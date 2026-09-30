// lib/screens/genre/genre_movies_screen.dart
// Shows all movies for a given genre, mixed with international titles
// (Hollywood + Bollywood + Korean + more) instead of just Hollywood.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/movie_model.dart';
import '../../api/tmdb_api.dart';
import '../../theme/app_theme.dart';
import '../../widgets/movie_card.dart';
import '../../widgets/shimmer_loading.dart';

class GenreMoviesScreen extends StatefulWidget {
  final int genreId;
  final String genreName;

  const GenreMoviesScreen({
    super.key,
    required this.genreId,
    required this.genreName,
  });

  @override
  State<GenreMoviesScreen> createState() => _GenreMoviesScreenState();
}

class _GenreMoviesScreenState extends State<GenreMoviesScreen> {
  late Future<List<Movie>> _future;

  @override
  void initState() {
    super.initState();
    _future = TmdbApi().getByGenreGlobal(widget.genreId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.genreName,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      body: FutureBuilder<List<Movie>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ShimmerMovieRow();
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off_rounded, color: AppColors.textMuted, size: 48),
                  const SizedBox(height: 12),
                  const Text('Failed to load movies',
                      style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Poppins')),
                ],
              ),
            );
          }
          final movies = snapshot.data ?? [];
          if (movies.isEmpty) {
            return const Center(
              child: Text('No movies found in this genre.',
                  style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Poppins')),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 115,
              childAspectRatio: 0.52,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
            ),
            itemCount: movies.length,
            itemBuilder: (context, i) {
              final movie = movies[i];
              return MovieCard(
                movie: movie,
                size: MovieCardSize.small,
                showTitle: true,
                onTap: () => context.push('/movie/${movie.id}', extra: movie),
                animationIndex: i,
              );
            },
          );
        },
      ),
    );
  }
}