// lib/screens/search/search_screen.dart
// Search screen with live results, suggestions, and recent history

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../api/api_constants.dart';
import '../../api/tmdb_api.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../models/movie_model.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/movie_card.dart';
import '../../widgets/rating_badge.dart';
import '../../widgets/shimmer_loading.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  bool _showResults = false;

  // Popular search suggestions
  static const List<String> _suggestions = [
    'Avengers', 'Interstellar', 'The Dark Knight', 'Inception',
    'Spider-Man', 'Avatar', 'John Wick', 'Dune',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    setState(() => _showResults = query.isNotEmpty);

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        ref.read(searchProvider.notifier).search(query);
        _saveSearch(query);
      } else {
        ref.read(searchProvider.notifier).clear();
      }
    });
  }

  void _saveSearch(String query) async {
    final user = ref.read(authStateProvider).value;
    if (user != null && query.length > 2) {
      await ref.read(firestoreServiceProvider).addSearchHistory(user.uid, query);
    }
  }

  void _openMovie(Movie movie) {
    context.push('/movie/${movie.id}', extra: movie);
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(searchProvider.notifier).clear();
    setState(() => _showResults = false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            _buildSearchBar(),

            // Body
            Expanded(
              child: _showResults
                  ? _buildSearchResults(searchState)
                  : _buildDiscoverState(userAsync.value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _focusNode.hasFocus
                      ? AppColors.primary.withOpacity(0.5)
                      : const Color(0xFF2A2A2A),
                ),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontFamily: 'Poppins',
                ),
                decoration: InputDecoration(
                  hintText: 'Search movies, genres...',
                  hintStyle: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                  ),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.textMuted, size: 22),
                  suffixIcon: _showResults
                      ? IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textMuted, size: 20),
                    onPressed: _clearSearch,
                  )
                      : IconButton(
                    icon: const Icon(Icons.mic_outlined,
                        color: AppColors.textMuted, size: 20),
                    onPressed: () {
                      // Voice search placeholder
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Voice search coming soon!'),
                          backgroundColor: AppColors.surface,
                        ),
                      );
                    },
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          if (_showResults) ...[
            const SizedBox(width: 10),
            TextButton(
              onPressed: _clearSearch,
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.primary,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDiscoverState(userModel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Searches
          if (userModel?.searchHistory.isNotEmpty == true) ...[
            _buildSectionTitle('Recent Searches', Icons.history_rounded,
                trailing: TextButton(
                  onPressed: () async {
                    final user = ref.read(authStateProvider).value;
                    if (user != null) {
                      await ref.read(firestoreServiceProvider).clearSearchHistory(user.uid);
                    }
                  },
                  child: const Text('Clear',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                )),
            _buildRecentSearches(userModel!.searchHistory),
            const SizedBox(height: 20),
          ],

          // Quick Suggestions
          _buildSectionTitle('Trending Searches', Icons.trending_up_rounded),
          const SizedBox(height: 12),
          _buildSuggestions(),

          const SizedBox(height: 28),

          // Popular genres
          _buildSectionTitle('Browse by Genre', Icons.category_rounded),
          const SizedBox(height: 12),
          _buildGenreGrid(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          ),
          const Spacer(),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildRecentSearches(List<String> history) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: history
          .reversed
          .take(10)
          .map(
            (q) => GestureDetector(
          onTap: () {
            _searchController.text = q;
            _searchController.selection = TextSelection.fromPosition(
              TextPosition(offset: q.length),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.history_rounded,
                    size: 14, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text(
                  q,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ),
      )
          .toList(),
    );
  }

  Widget _buildSuggestions() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _suggestions
          .map(
            (s) => GestureDetector(
          onTap: () {
            _searchController.text = s;
            _searchController.selection = TextSelection.fromPosition(
              TextPosition(offset: s.length),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.search, size: 13, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  s,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ),
      )
          .toList(),
    );
  }

  Widget _buildGenreGrid() {
    final genres = [
      ('Action', Icons.local_fire_department_rounded, const Color(0xFFE50914), ApiConstants.genreAction),
      ('Comedy', Icons.sentiment_very_satisfied_rounded, const Color(0xFFFFB800), ApiConstants.genreComedy),
      ('Horror', Icons.psychology_rounded, const Color(0xFF9B59B6), ApiConstants.genreHorror),
      ('Romance', Icons.favorite_rounded, const Color(0xFFE91E63), ApiConstants.genreRomance),
      ('Sci-Fi', Icons.rocket_launch_rounded, const Color(0xFF00D4FF), ApiConstants.genreSciFi),
      ('Drama', Icons.theater_comedy_rounded, const Color(0xFF2ECC71), ApiConstants.genreDrama),
      ('Thriller', Icons.remove_red_eye_rounded, const Color(0xFFF39C12), ApiConstants.genreThriller),
      ('Animation', Icons.animation_rounded, const Color(0xFF3498DB), ApiConstants.genreAnimation),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: genres.length,
      itemBuilder: (context, i) {
        final (name, icon, color, genreId) = genres[i];
        return GestureDetector(
          onTap: () => context.push('/genre/$genreId', extra: name),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Backdrop image (falls back to plain color while loading / if missing)
                Container(color: color.withValues(alpha: 0.25)),
                FutureBuilder<List<Movie>>(
                  future: TmdbApi().getByGenre(genreId),
                  builder: (context, snapshot) {
                    final movies = snapshot.data;
                    final backdrop = (movies != null && movies.isNotEmpty)
                        ? movies.first.backdropUrl
                        : '';
                    if (backdrop.isEmpty) return const SizedBox.shrink();
                    return CachedNetworkImage(
                      imageUrl: backdrop,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const SizedBox.shrink(),
                    );
                  },
                ),
                // Dark gradient so text stays readable
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black.withValues(alpha: 0.1), Colors.black.withValues(alpha: 0.75)],
                    ),
                  ),
                ),
                // Icon + name
                Positioned(
                  left: 12,
                  bottom: 10,
                  right: 12,
                  child: Row(
                    children: [
                      Icon(icon, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ).animate(delay: Duration(milliseconds: i * 50)).fadeIn().scale(begin: const Offset(0.9, 0.9));
      },
    );
  }

  Widget _buildSearchResults(searchState) {
    if (searchState.isLoading) {
      return const ShimmerMovieRow();
    }

    if (searchState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, color: AppColors.textMuted, size: 48),
            const SizedBox(height: 12),
            Text('Search failed', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(searchState.error!, style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    if (searchState.results.isEmpty && searchState.query.isNotEmpty) {
      return EmptyStateWidget(
        icon: Icons.search_off_rounded,
        title: 'No results found',
        subtitle: 'Try a different keyword or check your spelling.',
      );
    }

    if (searchState.results.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Text(
            '${searchState.results.length} results for "${searchState.query}"',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 115,
              childAspectRatio: 0.52,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
            ),
            itemCount: searchState.results.length,
            itemBuilder: (context, i) {
              final movie = searchState.results[i];
              return MovieCard(
                movie: movie,
                size: MovieCardSize.small,
                showTitle: true,
                onTap: () => _openMovie(movie),
                animationIndex: i,
              );
            },
          ),
        ),
      ],
    );
  }
}