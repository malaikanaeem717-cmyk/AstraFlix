// lib/api/tmdb_api.dart
// Service layer for all TMDB API calls

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie_model.dart';
import 'api_constants.dart';

class TmdbApi {
  static final TmdbApi _instance = TmdbApi._internal();
  factory TmdbApi() => _instance;
  TmdbApi._internal();

  final http.Client _client = http.Client();

  // ─── Simple in-memory TTL cache ────────────────────────────────────────
  final Map<String, _CacheEntry> _cache = {};

  Duration _durationFor(String endpoint) {
    if (endpoint.startsWith(ApiConstants.trending) ||
        endpoint.startsWith(ApiConstants.trendingDay)) {
      return ApiConstants.trendingCacheDuration;
    }
    if (endpoint.startsWith(ApiConstants.searchMovies) ||
        endpoint.startsWith(ApiConstants.searchMulti)) {
      return ApiConstants.searchCacheDuration;
    }
    return ApiConstants.movieCacheDuration;
  }

  void clearCache() => _cache.clear();

  Uri _buildUrl(String endpoint, [Map<String, String>? extraParams]) {
    final params = <String, String>{
      'api_key': ApiConstants.tmdbApiKey,
      'language': 'en-US',
      ...?extraParams,
    };
    return Uri.parse('${ApiConstants.tmdbBaseUrl}$endpoint')
        .replace(queryParameters: params);
  }

  Future<Map<String, dynamic>> _get(String endpoint,
      [Map<String, String>? params]) async {
    final uri = _buildUrl(endpoint, params);
    final cacheKey = uri.toString();

    final cached = _cache[cacheKey];
    if (cached != null && !cached.isExpired) {
      return cached.data;
    }

    try {
      final response = await _client.get(uri).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Request timed out'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        _cache[cacheKey] = _CacheEntry(data, DateTime.now().add(_durationFor(endpoint)));
        return data;
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API key. Please check your TMDB API key.');
      } else if (response.statusCode == 404) {
        throw Exception('Resource not found.');
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } catch (e) {
      if (cached != null) return cached.data;
      rethrow;
    }
  }

  Future<List<Movie>> getTrending({int page = 1}) async {
    final data = await _get(ApiConstants.trending, {'page': page.toString()});
    final results = data['results'] as List<dynamic>? ?? [];
    return results.map((m) => Movie.fromJson(m as Map<String, dynamic>)).toList();
  }

  Future<List<Movie>> getTrendingToday({int page = 1}) async {
    final data = await _get(ApiConstants.trendingDay, {'page': page.toString()});
    final results = data['results'] as List<dynamic>? ?? [];
    return results.map((m) => Movie.fromJson(m as Map<String, dynamic>)).toList();
  }

  Future<List<Movie>> getPopular({int page = 1}) async {
    final data = await _get(ApiConstants.popular, {'page': page.toString()});
    return _parseMovieList(data);
  }

  Future<List<Movie>> getTopRated({int page = 1}) async {
    final data = await _get(ApiConstants.topRated, {'page': page.toString()});
    return _parseMovieList(data);
  }

  Future<List<Movie>> getUpcoming({int page = 1}) async {
    final data = await _get(ApiConstants.upcoming, {'page': page.toString()});
    return _parseMovieList(data);
  }

  Future<List<Movie>> getNowPlaying({int page = 1}) async {
    final data = await _get(ApiConstants.nowPlaying, {'page': page.toString()});
    return _parseMovieList(data);
  }

  Future<List<Movie>> getByGenre(int genreId, {int page = 1}) async {
    final data = await _get('/discover/movie', {
      'with_genres': genreId.toString(),
      'page': page.toString(),
      'sort_by': 'popularity.desc',
    });
    return _parseMovieList(data);
  }

  Future<List<Movie>> getByGenreGlobal(int genreId) async {
    final futures = await Future.wait([
      getByGenre(genreId),
      getByGenreAndLanguage(genreId, ApiConstants.langHindi),
      getByGenreAndLanguage(genreId, ApiConstants.langKorean),
      getByGenreAndLanguage(genreId, ApiConstants.langUrdu),
    ]);

    final seen = <int>{};
    final mixed = <Movie>[];
    final maxLen = futures.map((l) => l.length).fold(0, (a, b) => a > b ? a : b);
    for (var i = 0; i < maxLen; i++) {
      for (final list in futures) {
        if (i < list.length && seen.add(list[i].id)) {
          mixed.add(list[i]);
        }
      }
    }
    return mixed;
  }

  Future<List<Movie>> getByGenreAndLanguage(int genreId, String langCode, {int page = 1}) async {
    final data = await _get('/discover/movie', {
      'with_genres': genreId.toString(),
      'with_original_language': langCode,
      'sort_by': 'popularity.desc',
      'page': page.toString(),
    });
    return _parseMovieList(data);
  }

  Future<List<Movie>> getActionMovies({int page = 1}) => getByGenre(ApiConstants.genreAction, page: page);
  Future<List<Movie>> getComedyMovies({int page = 1}) => getByGenre(ApiConstants.genreComedy, page: page);
  Future<List<Movie>> getHorrorMovies({int page = 1}) => getByGenre(ApiConstants.genreHorror, page: page);
  Future<List<Movie>> getRomanceMovies({int page = 1}) => getByGenre(ApiConstants.genreRomance, page: page);
  Future<List<Movie>> getSciFiMovies({int page = 1}) => getByGenre(ApiConstants.genreSciFi, page: page);
  Future<List<Movie>> getDramaMovies({int page = 1}) => getByGenre(ApiConstants.genreDrama, page: page);

  Future<Movie> getMovieDetails(int movieId) async {
    final data = await _get(ApiConstants.movieDetails(movieId));
    return Movie.fromJson(data);
  }

  Future<List<Movie>> searchMovies(String query, {int page = 1}) async {
    if (query.trim().isEmpty) return [];
    final data = await _get(ApiConstants.searchMovies, {
      'query': query.trim(),
      'page': page.toString(),
      'include_adult': 'false',
    });
    return _parseMovieList(data);
  }

  Future<List<Movie>> getRecommendations(int movieId, {int page = 1}) async {
    final data = await _get('/movie/$movieId/recommendations', {'page': page.toString()});
    return _parseMovieList(data);
  }

  Future<List<Movie>> getSimilarMovies(int movieId, {int page = 1}) async {
    final data = await _get('/movie/$movieId/similar', {'page': page.toString()});
    return _parseMovieList(data);
  }

  Future<List<Genre>> getGenres() async {
    final data = await _get(ApiConstants.genreList);
    final genres = data['genres'] as List<dynamic>? ?? [];
    return genres.map((g) => Genre.fromJson(g as Map<String, dynamic>)).toList();
  }

  Future<List<Movie>> getByLanguage(String langCode, {int page = 1}) async {
    final data = await _get('/discover/movie', {
      'with_original_language': langCode,
      'sort_by': 'popularity.desc',
      'page': page.toString(),
    });
    return _parseMovieList(data);
  }

  Future<List<Movie>> getHollywoodMovies({int page = 1}) => getByLanguage(ApiConstants.langEnglish, page: page);
  Future<List<Movie>> getBollywoodMovies({int page = 1}) => getByLanguage(ApiConstants.langHindi, page: page);
  Future<List<Movie>> getPakistaniMovies({int page = 1}) => getByLanguage(ApiConstants.langUrdu, page: page);
  Future<List<Movie>> getKoreanMovies({int page = 1}) => getByLanguage(ApiConstants.langKorean, page: page);
  Future<List<Movie>> getTurkishMovies({int page = 1}) => getByLanguage(ApiConstants.langTurkish, page: page);
  Future<List<Movie>> getJapaneseMovies({int page = 1}) => getByLanguage(ApiConstants.langJapanese, page: page);
  Future<List<Movie>> getChineseMovies({int page = 1}) => getByLanguage(ApiConstants.langChinese, page: page);
  Future<List<Movie>> getIndonesianMovies({int page = 1}) => getByLanguage(ApiConstants.langIndonesian, page: page);

  Future<Map<String, dynamic>> getWatchProviders(int movieId) async {
    final data = await _get(ApiConstants.watchProviders(movieId));
    return data['results'] as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, List<Movie>>> getHomeScreenData() async {
    final results = await Future.wait([
      getTrending(), getPopular(), getTopRated(), getActionMovies(),
      getComedyMovies(), getHorrorMovies(), getRomanceMovies(), getSciFiMovies(), getNowPlaying(),
    ]);
    return {
      'trending': results[0], 'popular': results[1], 'topRated': results[2],
      'action': results[3], 'comedy': results[4], 'horror': results[5],
      'romance': results[6], 'scifi': results[7], 'nowPlaying': results[8],
    };
  }

  List<Movie> _parseMovieList(Map<String, dynamic> data) {
    final results = data['results'] as List<dynamic>? ?? [];
    return results
        .map((m) => Movie.fromJson(m as Map<String, dynamic>))
        .where((m) => m.posterPath != null)
        .toList();
  }

  void dispose() {
    _client.close();
  }
}

class _CacheEntry {
  final Map<String, dynamic> data;
  final DateTime expiresAt;
  _CacheEntry(this.data, this.expiresAt);
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}