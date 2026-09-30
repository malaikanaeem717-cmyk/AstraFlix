// lib/api/recommendation_service.dart
// Service to connect with the FastAPI ML recommendation backend.
// Easily change the BASE_URL when deploying.

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie_model.dart';
import 'api_constants.dart';

/// RecommendationResult holds both the AI recommendations
/// and an optional message from the backend.
class RecommendationResult {
  final List<Movie> movies;
  final String? message;
  final bool isFromCache;
  final DateTime fetchedAt;

  const RecommendationResult({
    required this.movies,
    this.message,
    this.isFromCache = false,
    required this.fetchedAt,
  });
}
class RecommendationService {
  static final RecommendationService _instance = RecommendationService._internal();
  factory RecommendationService() => _instance;
  RecommendationService._internal();

  static String? _baseUrlOverride;

  static void setBaseUrl(String url) {
    _baseUrlOverride = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  static String get baseUrl => _baseUrlOverride ?? ApiConstants.recommendationBaseUrl;

  final http.Client _client = http.Client();
  // ─── Simple Cache ─────────────────────────────────────────────────────────
  final Map<String, RecommendationResult> _cache = {};

  // ─── Get Recommendations from ML Backend ──────────────────────────────────
  /// Calls GET /recommend?movie={movieTitle}
  /// Expected JSON response:
  /// [
  ///   { "title": "Iron Man", "poster": "https://...", "id": 1234, "rating": 7.5 },
  ///   ...
  /// ]
  Future<RecommendationResult> getRecommendations(String movieTitle) async {
    final cacheKey = movieTitle.toLowerCase().trim();

    // Return cached result if available and fresh
    if (_cache.containsKey(cacheKey)) {
      final cached = _cache[cacheKey]!;
      if (DateTime.now().difference(cached.fetchedAt) < ApiConstants.searchCacheDuration) {
        return RecommendationResult(
          movies: cached.movies,
          message: cached.message,
          isFromCache: true,
          fetchedAt: cached.fetchedAt,
        );
      }
    }

    try {
      final uri = Uri.parse('$baseUrl${ApiConstants.recommendEndpoint}')
          .replace(queryParameters: {'movie': movieTitle.trim()});

      final response = await _client
          .get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final movies = data
            .map((item) => _parseRecommendationItem(item as Map<String, dynamic>))
            .where((m) => m != null)
            .cast<Movie>()
            .toList();

        final result = RecommendationResult(
          movies: movies,
          fetchedAt: DateTime.now(),
        );
        _cache[cacheKey] = result;
        return result;
      } else if (response.statusCode == 404) {
        return RecommendationResult(
          movies: [],
          message: 'No recommendations found for "$movieTitle".',
          fetchedAt: DateTime.now(),
        );
      } else {
        throw Exception('Backend error: ${response.statusCode}');
      }
    } catch (e) {
      // If backend is unavailable, return empty with error message
      return RecommendationResult(
        movies: [],
        message: 'Recommendation service unavailable. Please try again later.',
        fetchedAt: DateTime.now(),
      );
    }
  }

  // ─── Advanced Recommendation with User Profile ────────────────────────────
  /// POST /recommend/personalized
  /// Sends user watch history for personalized recommendations.
  Future<RecommendationResult> getPersonalizedRecommendations({
    required List<String> watchedMovies,
    required List<String> favoriteGenres,
    int limit = 20,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/recommend/personalized');
      final body = json.encode({
        'watched_movies': watchedMovies,
        'favorite_genres': favoriteGenres,
        'limit': limit,
      });

      final response = await _client
          .post(uri,
              headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final movies = data
            .map((item) => _parseRecommendationItem(item as Map<String, dynamic>))
            .where((m) => m != null)
            .cast<Movie>()
            .toList();

        return RecommendationResult(movies: movies, fetchedAt: DateTime.now());
      } else {
        throw Exception('Personalized recommendation error: ${response.statusCode}');
      }
    } catch (e) {
      return RecommendationResult(
        movies: [],
        message: 'Unable to fetch personalized recommendations.',
        fetchedAt: DateTime.now(),
      );
    }
  }

  // ─── Health Check ─────────────────────────────────────────────────────────
  Future<bool> isBackendAvailable() async {
    try {
      final uri = Uri.parse('$baseUrl/health');
      final response =
          await _client.get(uri).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ─── Parse Flexible API Response ──────────────────────────────────────────
  // Handles multiple possible response formats from the FastAPI backend
  Movie? _parseRecommendationItem(Map<String, dynamic> item) {
    try {
      // Format 1: Full TMDB-like format
      if (item.containsKey('id') && item.containsKey('title')) {
        return Movie.fromJson(item);
      }
      // Format 2: Simple format { "title": "...", "poster": "...", "rating": ... }
      final poster = item['poster'] as String?;
      final posterPath = poster != null
          ? (poster.startsWith('/') ? poster : null)
          : null;
      final posterUrl = poster != null && poster.startsWith('http')
          ? poster
          : null;

      return Movie(
        id: item['id'] ?? DateTime.now().millisecondsSinceEpoch,
        title: item['title'] ?? '',
        posterPath: posterPath,
        backdropPath: item['backdrop_path'],
        voteAverage: (item['rating'] ?? item['vote_average'] ?? 0.0).toDouble(),
        releaseDate: item['release_date'] ?? item['year']?.toString(),
        overview: item['overview'] ?? item['description'],
        genreIds: List<int>.from(item['genre_ids'] ?? []),
      );
    } catch (_) {
      return null;
    }
  }

  void clearCache() => _cache.clear();

  void dispose() {
    _client.close();
  }
}
