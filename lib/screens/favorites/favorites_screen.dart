// lib/screens/favorites/favorites_screen.dart
// "My List" — Favorites and Watchlist as two tabs in one screen, both with
// real-time Firestore sync. (Previously Watchlist had its own screen file
// but no way to actually reach it — this is what fixes that.)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/movie_model.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/movie_card.dart';
import '../../widgets/rating_badge.dart';
import '../../widgets/shimmer_loading.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          'My List',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800, fontFamily: 'Poppins'),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 13.5),
          unselectedLabelStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, fontSize: 13.5),
          tabs: const [
            Tab(icon: Icon(Icons.favorite_rounded, size: 18), text: 'Favorites'),
            Tab(icon: Icon(Icons.bookmark_rounded, size: 18), text: 'Watchlist'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _FavoritesTab(),
          _WatchlistTab(),
        ],
      ),
    );
  }
}

class _FavoritesTab extends ConsumerWidget {
  const _FavoritesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritesProvider);
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return EmptyStateWidget(
            icon: Icons.favorite_border_rounded,
            title: 'Sign in to see favorites',
            subtitle: 'Create an account to save and sync your favorite movies.',
            buttonLabel: 'Sign In',
            onButtonTap: () => context.push('/login'),
          );
        }

        return favoritesAsync.when(
          data: (movies) {
            if (movies.isEmpty) {
              return EmptyStateWidget(
                icon: Icons.favorite_border_rounded,
                title: 'No favorites yet',
                subtitle: 'Tap the ❤️ on any movie to add it to your favorites — or just ask Astra to.',
                buttonLabel: 'Discover Movies',
                onButtonTap: () => ref.read(navIndexProvider.notifier).state = 0,
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Text(
                    '${movies.length} movie${movies.length != 1 ? 's' : ''}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13, fontFamily: 'Poppins'),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.62,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: movies.length,
                    itemBuilder: (context, i) {
                      final movie = movies[i];
                      return GestureDetector(
                        onLongPress: () => _showRemoveDialog(context, ref, user.uid, movie.id, movie.title),
                        child: MovieCard(
                          movie: movie,
                          size: MovieCardSize.small,
                          showTitle: true,
                          animationIndex: i,
                          onTap: () => context.push('/movie/${movie.id}', extra: movie),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => const ShimmerMovieRow(),
          error: (e, _) => AstraErrorWidget(
            message: e.toString(),
            onRetry: () => ref.invalidate(favoritesProvider),
          ),
        );
      },
      loading: () => const Center(child: AstraLoadingIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _showRemoveDialog(BuildContext context, WidgetRef ref, String uid, int movieId, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Favorite?',
            style: TextStyle(color: AppColors.textPrimary, fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: Text(
          'Remove "$title" from your favorites?',
          style: const TextStyle(color: AppColors.textSecondary, fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted, fontFamily: 'Poppins')),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(firestoreServiceProvider).removeFromFavorites(uid, movieId);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Remove', style: TextStyle(color: AppColors.primary, fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _WatchlistTab extends ConsumerWidget {
  const _WatchlistTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchlistAsync = ref.watch(watchlistProvider);
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return EmptyStateWidget(
            icon: Icons.bookmark_border_rounded,
            title: 'Sign in to use Watchlist',
            subtitle: 'Save movies to watch later and sync across devices.',
            buttonLabel: 'Sign In',
            onButtonTap: () => context.push('/login'),
          );
        }

        return watchlistAsync.when(
          data: (movies) {
            if (movies.isEmpty) {
              return EmptyStateWidget(
                icon: Icons.bookmark_border_rounded,
                title: 'Watchlist is empty',
                subtitle: 'Add movies to watch later by tapping 🔖 on any movie — or just ask Astra to.',
                buttonLabel: 'Browse Movies',
                onButtonTap: () => ref.read(navIndexProvider.notifier).state = 0,
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: movies.length,
              itemBuilder: (context, i) {
                final movie = movies[i];
                return _WatchlistItem(
                  movie: movie,
                  onTap: () => context.push('/movie/${movie.id}', extra: movie),
                  onRemove: () async {
                    await ref.read(firestoreServiceProvider).removeFromWatchlist(user.uid, movie.id);
                  },
                ).animate().fadeIn(delay: (i * 30).ms);
              },
            );
          },
          loading: () => const ShimmerMovieRow(),
          error: (e, _) => AstraErrorWidget(message: e.toString()),
        );
      },
      loading: () => const Center(child: AstraLoadingIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _WatchlistItem extends StatelessWidget {
  final Movie movie;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _WatchlistItem({required this.movie, required this.onTap, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('watchlist_${movie.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 24),
      ),
      confirmDismiss: (_) async {
        onRemove();
        return true;
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF2A2A2A)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: movie.posterUrl.isNotEmpty
                    ? CachedNetworkImage(
                  imageUrl: movie.posterUrl,
                  width: 65,
                  height: 96,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(width: 65, height: 96, color: AppColors.surfaceVariant),
                  errorWidget: (_, __, ___) => Container(
                    width: 65,
                    height: 96,
                    color: AppColors.surfaceVariant,
                    child: const Icon(Icons.movie, color: AppColors.textMuted),
                  ),
                )
                    : Container(
                  width: 65,
                  height: 96,
                  color: AppColors.surfaceVariant,
                  child: const Icon(Icons.movie, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (movie.year.isNotEmpty) ...[
                          Text(movie.year,
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontFamily: 'Poppins')),
                          const SizedBox(width: 8),
                        ],
                        if (movie.voteAverage > 0) RatingBadge(rating: movie.voteAverage, compact: true),
                      ],
                    ),
                    if (movie.overview != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        movie.overview!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontFamily: 'Poppins', height: 1.4),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _smallButton(icon: Icons.play_arrow_rounded, label: 'Details', onTap: onTap, color: AppColors.primary),
                        const SizedBox(width: 8),
                        _smallButton(icon: Icons.delete_outline_rounded, label: 'Remove', onTap: onRemove, color: AppColors.error),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _smallButton({required IconData icon, required String label, required VoidCallback onTap, required Color color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
          ],
        ),
      ),
    );
  }
}