// lib/screens/details/movie_details_screen.dart
// Full movie details with backdrop, cast, inline trailer player, and user actions

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../models/movie_model.dart';
import '../../providers/app_providers.dart';
import '../../api/tmdb_api.dart';
import '../../api/api_constants.dart';
import '../../theme/app_theme.dart';
import '../../widgets/movie_card.dart';
import '../../widgets/shimmer_loading.dart';

class MovieDetailsScreen extends ConsumerStatefulWidget {
  final int movieId;
  final Movie? preloadedMovie;

  const MovieDetailsScreen({
    super.key,
    required this.movieId,
    this.preloadedMovie,
  });

  @override
  ConsumerState<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends ConsumerState<MovieDetailsScreen> {
  bool _isFavorite = false;
  bool _isInWatchlist = false;
  bool _favoriteLoading = false;
  bool _watchlistLoading = false;

  // Inline trailer player state
  YoutubePlayerController? _ytController;
  bool _showTrailerPlayer = false;

  // Used to scroll down to the inline "Similar Movies" section when the
  // Similar button is tapped, instead of navigating to a separate screen.
  final GlobalKey _similarMoviesKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadUserMovieStatus();
    _trackRecentlyViewed();
  }

  @override
  void dispose() {
    _ytController?.close();
    super.dispose();
  }

  Future<void> _loadUserMovieStatus() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    final firestore = ref.read(firestoreServiceProvider);
    final fav = await firestore.isFavorite(user.uid, widget.movieId);
    final wl = await firestore.isInWatchlist(user.uid, widget.movieId);
    if (mounted) setState(() { _isFavorite = fav; _isInWatchlist = wl; });
  }

  Future<void> _trackRecentlyViewed() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    await ref.read(firestoreServiceProvider).addToRecentlyViewed(user.uid, widget.movieId);
  }

  Future<void> _toggleFavorite(Movie movie) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) { context.push('/login'); return; }
    setState(() => _favoriteLoading = true);
    final firestore = ref.read(firestoreServiceProvider);
    try {
      if (_isFavorite) {
        await firestore.removeFromFavorites(user.uid, movie.id);
      } else {
        await firestore.addToFavorites(user.uid, movie);
      }
      setState(() => _isFavorite = !_isFavorite);
    } finally {
      if (mounted) setState(() => _favoriteLoading = false);
    }
  }

  Future<void> _toggleWatchlist(Movie movie) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) { context.push('/login'); return; }
    setState(() => _watchlistLoading = true);
    final firestore = ref.read(firestoreServiceProvider);
    try {
      if (_isInWatchlist) {
        await firestore.removeFromWatchlist(user.uid, movie.id);
      } else {
        await firestore.addToWatchlist(user.uid, movie);
      }
      setState(() => _isInWatchlist = !_isInWatchlist);
    } finally {
      if (mounted) setState(() => _watchlistLoading = false);
    }
  }

  // ─── Play trailer inline (in-app) when "Watch Now" is tapped ─────────────
  void _playTrailerInline(Movie movie) {
    final trailers = movie.videos.where((v) => v.isTrailer).toList();
    if (trailers.isEmpty) {
      // TMDB ke paas is movie ka trailer link maujood nahi — YouTube pe
      // khud search kar ke khol dein, taake dead-end na aaye.
      _openYoutubeSearch('${movie.title} official trailer');
      return;
    }
    final trailer = trailers.first;
    _ytController?.close();
    _ytController = YoutubePlayerController.fromVideoId(
      videoId: trailer.key,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showFullscreenButton: true,
        mute: false,
      ),
    );
    setState(() => _showTrailerPlayer = true);
  }

  void _closeTrailerPlayer() {
    _ytController?.pauseVideo();
    setState(() => _showTrailerPlayer = false);
  }

  // Scrolls down to the already-visible "Similar Movies" section on this
  // same page, rather than navigating away to a separate screen/chat.
  void _scrollToSimilarMovies() {
    final ctx = _similarMoviesKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.05,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No similar movies found for this title.')),
      );
    }
  }

  Future<void> _openYoutubeSearch(String query) async {
    // Pehle YouTube Data API se asal trailer video dhoondein, taake
    // seedha isi app ke andar chal jaye (external site khulne ki bajaye).
    if (ApiConstants.youtubeApiKey.isNotEmpty &&
        ApiConstants.youtubeApiKey != 'YAHAN_APNI_KEY_PASTE_KAREIN') {
      try {
        final uri = Uri.parse('https://www.googleapis.com/youtube/v3/search').replace(
          queryParameters: {
            'part': 'snippet',
            'q': query,
            'type': 'video',
            'maxResults': '1',
            'key': ApiConstants.youtubeApiKey,
          },
        );
        final response = await http.get(uri);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final items = data['items'] as List<dynamic>? ?? [];
          if (items.isNotEmpty) {
            final videoId = items.first['id']['videoId'] as String;
            _ytController?.close();
            _ytController = YoutubePlayerController.fromVideoId(
              videoId: videoId,
              autoPlay: true,
              params: const YoutubePlayerParams(showFullscreenButton: true, mute: false),
            );
            if (mounted) setState(() => _showTrailerPlayer = true);
            return;
          }
        }
      } catch (_) {
        // Neeche fallback chalega
      }
    }

    // Fallback: agar API key na ho ya search fail ho jaye, tab hi
    // external YouTube site kholein.
    final uri = Uri.parse(
        'https://www.youtube.com/results?search_query=${Uri.encodeComponent(query)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final movieAsync = ref.watch(movieDetailsProvider(widget.movieId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: movieAsync.when(
        data: (movie) => _showTrailerPlayer
            ? _buildTrailerFullView(movie)
            : _buildContent(movie),
        loading: () => _buildLoadingState(),
        error: (e, _) => _buildErrorState(e.toString()),
      ),
    );
  }
  Widget _buildTrailerFullView(Movie movie) {
    return SafeArea(
      child: Column(
        children: [
          Container(
            height: kToolbarHeight,
            color: AppColors.background,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: _closeTrailerPlayer,
                ),
                Expanded(
                  child: Text(
                    movie.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Video area — jitni bhi jagah bachi hai (LayoutBuilder se pata
          // chalta hai), usi ke andar 16:9 ratio fit karo. Chahe width
          // zyada ho ya height, kabhi overflow nahi hoga, na kabhi
          // zaroorat se zyada bada dikhega.
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth;
                final maxHeight = constraints.maxHeight;

                // Available space ke hisaab se best-fit width/height nikalo
                double videoWidth = maxWidth;
                double videoHeight = videoWidth * 9 / 16;

                if (videoHeight > maxHeight) {
                  videoHeight = maxHeight;
                  videoWidth = videoHeight * 16 / 9;
                }

                return Center(
                  child: SizedBox(
                    width: videoWidth,
                    height: videoHeight,
                    child: _buildTrailerPlayer(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildLoadingState() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: AppColors.background,
          leading: _backButton(),
          expandedHeight: 300,
        ),
        const SliverToBoxAdapter(child: ShimmerMovieDetail()),
      ],
    );
  }

  Widget _buildErrorState(String error) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: _backButton(),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text('Failed to load movie', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(error, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(Movie movie) {
    return CustomScrollView(
      slivers: [
        // Collapsing backdrop header (or inline trailer player when playing)
        SliverAppBar(
          expandedHeight: 320,
          pinned: true,
          backgroundColor: AppColors.background,
          leading: _showTrailerPlayer
              ? IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.glassBlack,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
            ),
            onPressed: _closeTrailerPlayer,
          )
              : _backButton(),
          actions: _showTrailerPlayer
              ? []
              : [
            IconButton(
              icon: const Icon(Icons.share_outlined, color: Colors.white),
              onPressed: () {},
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: _showTrailerPlayer
                ? _buildTrailerPlayer()
                : _buildBackdrop(movie),
          ),
        ),

        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMovieHeader(movie).animate().fadeIn().slideY(begin: 0.2),
              _buildWatchNowButton(movie).animate().fadeIn(delay: 80.ms),
              _buildActionButtons(movie).animate().fadeIn(delay: 100.ms),
              if (movie.overview != null && movie.overview!.isNotEmpty)
                _buildOverview(movie).animate().fadeIn(delay: 150.ms),
              if (movie.cast.isNotEmpty)
                _buildCast(movie).animate().fadeIn(delay: 200.ms),
              if (movie.videos.isNotEmpty)
                _buildTrailerSection(movie).animate().fadeIn(delay: 250.ms),
              if (movie.similar.isNotEmpty)
                KeyedSubtree(
                  key: _similarMoviesKey,
                  child: _buildSimilarMovies(movie).animate().fadeIn(delay: 300.ms),
                ),
              _buildRatingSection(movie).animate().fadeIn(delay: 350.ms),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Inline YouTube player (replaces backdrop while a trailer is playing) ─
  Widget _buildTrailerPlayer() {
    if (_ytController == null) return const SizedBox.shrink();
    return Container(
      color: Colors.black,
      child: YoutubePlayer(
        controller: _ytController!,
        aspectRatio: 16 / 9,
      ),
    );
  }

  Widget _buildBackdrop(Movie movie) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Hero(
          tag: 'movie_${movie.id}',
          child: movie.backdropUrl.isNotEmpty
              ? CachedNetworkImage(
            imageUrl: movie.backdropUrl,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: AppColors.surfaceVariant),
            errorWidget: (_, __, ___) => _buildPosterFallback(movie),
          )
              : _buildPosterFallback(movie),
        ),
        // Gradient overlay
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x330A0A0A),
                Color(0x800A0A0A),
                Color(0xFF0A0A0A),
              ],
              stops: [0.0, 0.6, 1.0],
            ),
          ),
        ),
        // Poster overlay bottom-left
        Positioned(
          bottom: 16,
          left: 16,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: movie.posterUrl,
                  width: 80,
                  height: 120,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    width: 80,
                    height: 120,
                    color: AppColors.surfaceVariant,
                  ),
                  errorWidget: (_, __, ___) => Container(
                    width: 80,
                    height: 120,
                    color: AppColors.surfaceVariant,
                    child: const Icon(Icons.movie, color: AppColors.textMuted),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPosterFallback(Movie movie) {
    return Container(
      color: AppColors.surfaceVariant,
      child: movie.posterUrl.isNotEmpty
          ? CachedNetworkImage(imageUrl: movie.posterUrl, fit: BoxFit.cover)
          : const Icon(Icons.movie, size: 64, color: AppColors.textMuted),
    );
  }

  Widget _buildMovieHeader(Movie movie) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            movie.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              fontFamily: 'Poppins',
              height: 1.2,
            ),
          ),
          if (movie.tagline != null && movie.tagline!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '"${movie.tagline}"',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                fontStyle: FontStyle.italic,
                fontFamily: 'Poppins',
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Meta row
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              if (movie.voteAverage > 0)
                _metaBadge(
                  icon: Icons.star_rounded,
                  label: '${movie.ratingFormatted}/10',
                  color: AppColors.secondary,
                ),
              if (movie.year.isNotEmpty)
                _metaBadge(icon: Icons.calendar_today_outlined, label: movie.year),
              if (movie.runtimeFormatted.isNotEmpty)
                _metaBadge(icon: Icons.schedule_rounded, label: movie.runtimeFormatted),
              if (movie.originalLanguage != null)
                _metaBadge(
                  icon: Icons.language_rounded,
                  label: movie.originalLanguage!.toUpperCase(),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // Genres
          if (movie.genres.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: movie.genres
                  .take(4)
                  .map((g) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  g.name,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _metaBadge({required IconData icon, required String label, Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color ?? AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color ?? AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  // ─── Watch Now button → plays trailer inline, + small "where to watch" link ─
  Widget _buildWatchNowButton(Movie movie) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: () => _playTrailerInline(movie),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: AppColors.primaryGradient),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow_rounded, color: Colors.white),
                  SizedBox(width: 6),
                  Text('Watch Now',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: GestureDetector(
              onTap: () => _showWatchProviders(context, movie),
              child: const Text('Kahan stream ho rahi hai? →',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins')),
            ),
          ),
        ],
      ),
    );
  }
// Har platform ka apna search URL banata hai, taake click karte hi
  // seedha us platform pe movie search hoke khule.
  String? _platformSearchLink(String providerName, String movieTitle) {
    final query = Uri.encodeComponent(movieTitle);
    final name = providerName.toLowerCase();

    if (name.contains('netflix')) {
      return 'https://www.netflix.com/search?q=$query';
    }
    if (name.contains('prime') || name.contains('amazon')) {
      return 'https://www.primevideo.com/search/?phrase=$query';
    }
    if (name.contains('disney')) {
      return 'https://www.disneyplus.com/search?q=$query';
    }
    if (name.contains('hulu')) {
      return 'https://www.hulu.com/search?q=$query';
    }
    if (name.contains('hbo') || name.contains('max')) {
      return 'https://play.max.com/search?q=$query';
    }
    if (name.contains('apple')) {
      return 'https://tv.apple.com/search?term=$query';
    }
    if (name.contains('youtube')) {
      return 'https://www.youtube.com/results?search_query=$query+full+movie';
    }
    if (name.contains('paramount')) {
      return 'https://www.paramountplus.com/search/?q=$query';
    }
    return null; // Is provider ka koi specific search page nahi pata
  }
  Future<void> _showWatchProviders(BuildContext context, Movie movie) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => FutureBuilder<Map<String, dynamic>>(
        future: TmdbApi().getWatchProviders(movie.id),
        builder: (ctx, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            );
          }
          final results = snapshot.data!;
          // Pehle apna country try karein, warna jo bhi mile
          final country = results['PK'] ?? results['IN'] ?? results['US'] ??
              results['GB'] ?? results['CA'] ?? results['AU'] ?? results['AE'] ??
              results['SA'] ?? results['DE'] ?? results['FR'] ??
              (results.isNotEmpty ? results.values.first : null);

          if (country == null) {
            // TMDB/JustWatch ke pass is region ka data nahi hai — iska matlab
            // ye nahi ke movie kahin available nahi. Har major platform ka
            // direct search button de do, taake user khud confirm kar sake.
            final majorPlatforms = [
              {'name': 'Netflix', 'color': const Color(0xFFE50914)},
              {'name': 'Prime Video', 'color': const Color(0xFF00A8E1)},
              {'name': 'Disney+', 'color': const Color(0xFF113CCF)},
              {'name': 'Apple TV', 'color': const Color(0xFF000000)},
              {'name': 'YouTube', 'color': const Color(0xFFFF0000)},
            ];
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Kahan dekhein',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 18,
                          fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                  const SizedBox(height: 6),
                  const Text(
                    'Is region ke liye exact info maujood nahi — kisi bhi platform pe check kar lein:',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: majorPlatforms.map((p) {
                      final name = p['name'] as String;
                      final color = p['color'] as Color;
                      return GestureDetector(
                        onTap: () async {
                          final deepLink = _platformSearchLink(name, movie.title);
                          if (deepLink != null) {
                            await launchUrl(Uri.parse(deepLink),
                                mode: LaunchMode.externalApplication);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: color.withValues(alpha: 0.4)),
                          ),
                          child: Text(name,
                              style: TextStyle(color: color == const Color(0xFF000000)
                                  ? AppColors.textPrimary : color,
                                  fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () async {
                      final q = Uri.encodeComponent('watch ${movie.title} online');
                      final uri = Uri.parse('https://www.google.com/search?q=$q');
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                    child: const Text('Google pe search karein →',
                        style: TextStyle(color: AppColors.primary, fontSize: 13,
                            fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
                  ),
                ],
              ),
            );
          }

          final flatrate = (country['flatrate'] as List<dynamic>? ?? []);
          final rent = (country['rent'] as List<dynamic>? ?? []);
          final buy = (country['buy'] as List<dynamic>? ?? []);
          final link = country['link'] as String?;

          // ── Dedupe: same provider (e.g. Amazon Video) aksar flatrate + rent
          // + buy teenon lists mein hoti hai — provider_id se ek hi baar lein ──
          final Map<int, dynamic> uniqueProviders = {};
          for (final p in [...flatrate, ...rent, ...buy]) {
            final id = p['provider_id'] as int?;
            if (id != null && !uniqueProviders.containsKey(id)) {
              uniqueProviders[id] = p;
            }
          }
          final allProviders = uniqueProviders.values.toList();

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Kahan dekhein',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 18,
                        fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                const SizedBox(height: 16),
                if (allProviders.isEmpty)
                  const Text('Streaming info abhi maujood nahi.',
                      style: TextStyle(color: AppColors.textSecondary))
                else
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: allProviders.map((p) {
                      final name = p['provider_name'] as String? ?? '';
                      final logo = p['logo_path'] as String?;
                      return GestureDetector(
                        onTap: () async {
                          final deepLink = _platformSearchLink(name, movie.title);
                          final target = deepLink ?? link;
                          if (target != null) {
                            await launchUrl(Uri.parse(target),
                                mode: LaunchMode.externalApplication);
                          }
                        },
                        child: Column(children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: logo != null
                                ? Image.network('https://image.tmdb.org/t/p/w92$logo',
                                width: 50, height: 50, fit: BoxFit.cover)
                                : Container(width: 50, height: 50, color: AppColors.surfaceVariant),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 60,
                            child: Text(name, textAlign: TextAlign.center, maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                          ),
                        ]),
                      );
                    }).toList(),
                  ),
                if (link != null) ...[
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () async {
                      await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
                    },
                    child: const Text('Sab platforms dekhein →',
                        style: TextStyle(color: AppColors.primary, fontSize: 13,
                            fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButtons(Movie movie) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        children: [
          // Favorite
          Expanded(
            child: _ActionButton(
              icon: _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              label: _isFavorite ? 'Favorited' : 'Favorite',
              color: _isFavorite ? AppColors.primary : null,
              isLoading: _favoriteLoading,
              onTap: () => _toggleFavorite(movie),
            ),
          ),
          const SizedBox(width: 10),
          // Watchlist
          Expanded(
            child: _ActionButton(
              icon: _isInWatchlist
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              label: _isInWatchlist ? 'In Watchlist' : 'Watchlist',
              color: _isInWatchlist ? AppColors.secondary : null,
              isLoading: _watchlistLoading,
              onTap: () => _toggleWatchlist(movie),
            ),
          ),
          const SizedBox(width: 10),
          // Similar movies — scroll to the section already on this page
          Expanded(
            child: _ActionButton(
              icon: Icons.auto_awesome_rounded,
              label: 'Similar',
              color: AppColors.tertiary,
              onTap: _scrollToSimilarMovies,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverview(Movie movie) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overview',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            movie.overview!,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.6,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCast(Movie movie) {
    final topCast = movie.cast.take(10).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Text(
            'Cast',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: topCast.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) => _CastCard(member: topCast[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildTrailerSection(Movie movie) {
    final trailers = movie.videos.where((v) => v.isTrailer).take(3).toList();
    if (trailers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Text(
            'Trailers & Videos',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: trailers.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _TrailerCard(
              video: trailers[i],
              onTap: () {
                _ytController?.close();
                _ytController = YoutubePlayerController.fromVideoId(
                  videoId: trailers[i].key,
                  autoPlay: true,
                  params: const YoutubePlayerParams(showFullscreenButton: true, mute: false),
                );
                setState(() => _showTrailerPlayer = true);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimilarMovies(Movie movie) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Text(
            'More Like This',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        SizedBox(
          height: 195,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: movie.similar.take(10).length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final m = movie.similar[i];
              return MovieCard(
                movie: m,
                size: MovieCardSize.medium,
                onTap: () => context.push('/movie/${m.id}', extra: m),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRatingSection(Movie movie) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rate This Movie',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 12),
            RatingBar.builder(
              initialRating: 0,
              minRating: 0.5,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemSize: 32,
              unratedColor: AppColors.surfaceVariant,
              itemBuilder: (context, _) =>
              const Icon(Icons.star_rounded, color: AppColors.secondary),
              onRatingUpdate: (rating) async {
                final user = ref.read(authStateProvider).value;
                if (user != null) {
                  await ref.read(firestoreServiceProvider)
                      .rateMovie(user.uid, movie.id, rating * 2);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Rated ${(rating * 2).toStringAsFixed(1)}/10'),
                        backgroundColor: AppColors.surface,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _backButton() {
    return IconButton(
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.glassBlack,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.arrow_back_ios_rounded,
            color: Colors.white, size: 18),
      ),
      onPressed: () => context.pop(),
    );
  }
}

// ─── Cast Card ────────────────────────────────────────────────────────────────
class _CastCard extends StatelessWidget {
  final CastMember member;
  const _CastCard({required this.member});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(36),
            child: member.profileUrl.isNotEmpty
                ? CachedNetworkImage(
              imageUrl: member.profileUrl,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                width: 64,
                height: 64,
                color: AppColors.surfaceVariant,
              ),
              errorWidget: (_, __, ___) => _noPhotoAvatar(),
            )
                : _noPhotoAvatar(),
          ),
          const SizedBox(height: 6),
          Text(
            member.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
              height: 1.2,
            ),
          ),
          if (member.character != null)
            Text(
              member.character!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 9,
                fontFamily: 'Poppins',
              ),
            ),
        ],
      ),
    );
  }

  Widget _noPhotoAvatar() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }
}

// ─── Trailer Card ─────────────────────────────────────────────────────────────
class _TrailerCard extends StatelessWidget {
  final Video video;
  final VoidCallback onTap;
  const _TrailerCard({required this.video, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CachedNetworkImage(
              imageUrl: video.youtubeThumbnail,
              width: 160,
              height: 90,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                width: 160,
                height: 90,
                color: AppColors.surfaceVariant,
              ),
              errorWidget: (_, __, ___) => Container(
                width: 160,
                height: 90,
                color: AppColors.surfaceVariant,
                child: const Icon(Icons.play_circle, color: AppColors.textMuted, size: 32),
              ),
            ),
          ),
          // Play overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Icon(Icons.play_circle_filled_rounded,
                    color: Colors.white, size: 36),
              ),
            ),
          ),
          // Label
          Positioned(
            bottom: 6,
            left: 8,
            right: 8,
            child: Text(
              video.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                shadows: [Shadow(blurRadius: 4, color: Colors.black)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action Button ────────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final bool isLoading;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.color,
    this.isLoading = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color != null
              ? color!.withValues(alpha: 0.15)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color != null ? color!.withValues(alpha: 0.3) : const Color(0xFF2A2A2A),
          ),
        ),
        child: isLoading
            ? const SizedBox(
          height: 20,
          child: Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.primary),
            ),
          ),
        )
            : Column(
          children: [
            Icon(icon, color: color ?? AppColors.textSecondary, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color ?? AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}