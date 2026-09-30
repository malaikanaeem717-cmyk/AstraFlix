// lib/widgets/movie_card.dart
// Reusable Netflix-style movie card with Hero animation

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/movie_model.dart';
import '../theme/app_theme.dart';
import 'rating_badge.dart';

enum MovieCardSize { small, medium, large, featured }

class MovieCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback? onTap;
  final MovieCardSize size;
  final bool showRating;
  final bool showTitle;
  final int animationIndex;

  const MovieCard({
    super.key,
    required this.movie,
    this.onTap,
    this.size = MovieCardSize.medium,
    this.showRating = true,
    this.showTitle = false,
    this.animationIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final dimensions = _getDimensions();

    return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
            onTap: onTap,
            child: Hero(
        tag: 'movie_${movie.id}',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: dimensions.$1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Poster Image
              ClipRRect(
                borderRadius: BorderRadius.circular(
                  size == MovieCardSize.small ? 8 : 12,
                ),
                child: Stack(
                  children: [
                    // Movie Poster
                    _buildPosterImage(dimensions.$1, dimensions.$2),

                    // Gradient overlay for rating
                    if (showRating)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 60,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: AppColors.cardGradient,
                            ),
                          ),
                        ),
                      ),

                    // Rating badge
                    if (showRating && movie.voteAverage > 0)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: RatingBadge(rating: movie.voteAverage),
                      ),

                    // Favorite indicator
                    if (movie.isFavorite)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.favorite,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Title (optional)
              if (showTitle) ...[
                const SizedBox(height: 6),
                Text(
                  movie.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
                if (movie.year.isNotEmpty)
                  Text(
                    movie.year,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    )
    )
        .animate(delay: Duration(milliseconds: animationIndex * 50))
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.1, end: 0, duration: 300.ms, curve: Curves.easeOut);

  }

  Widget _buildPosterImage(double width, double height) {
    if (movie.posterUrl.isEmpty) {
      return _buildPlaceholder(width, height);
    }

    return CachedNetworkImage(
      imageUrl: movie.posterUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      placeholder: (context, url) => _buildShimmer(width, height),
      errorWidget: (context, url, error) => _buildPlaceholder(width, height),
    );
  }

  Widget _buildShimmer(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(
          size == MovieCardSize.small ? 8 : 12,
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildPlaceholder(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(
          size == MovieCardSize.small ? 8 : 12,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.movie_outlined,
            size: width * 0.25,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              movie.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Returns (width, height) based on card size
  (double, double) _getDimensions() {
    switch (size) {
      case MovieCardSize.small:
        return (100, 150);
      case MovieCardSize.medium:
        return (130, 195);
      case MovieCardSize.large:
        return (160, 240);
      case MovieCardSize.featured:
        return (200, 300);
    }
  }
}

// ─── Horizontal Movie List ─────────────────────────────────────────────────────
class MovieRow extends StatelessWidget {
  final String title;
  final List<Movie> movies;
  final Function(Movie) onMovieTap;
  final VoidCallback? onSeeAllTap;
  final MovieCardSize cardSize;

  const MovieRow({
    super.key,
    required this.title,
    required this.movies,
    required this.onMovieTap,
    this.onSeeAllTap,
    this.cardSize = MovieCardSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    if (movies.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              if (onSeeAllTap != null)
                GestureDetector(
                  onTap: onSeeAllTap,
                  child: Row(
                    children: [
                      Text(
                        'See All',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 11,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // Horizontal Scroll
        SizedBox(
          height: cardSize == MovieCardSize.small
              ? 150
              : cardSize == MovieCardSize.medium
                  ? 195
                  : cardSize == MovieCardSize.large
                      ? 240
                      : 300,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: movies.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final movie = movies[index];
              return MovieCard(
                movie: movie,
                size: cardSize,
                onTap: () => onMovieTap(movie),
                animationIndex: index,
              );
            },
          ),
        ),
      ],
    );
  }
}
