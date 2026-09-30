// lib/providers/app_providers.dart
// All Riverpod providers for AstraFlix — services, auth, movies, search, recommendations.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/movie_model.dart';
import '../models/user_model.dart';
import '../api/tmdb_api.dart';
import '../api/recommendation_service.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

// ─── Service singletons ────────────────────────────────────────────────────────
final tmdbApiProvider = Provider<TmdbApi>((_) => TmdbApi());
final authServiceProvider = Provider<AuthService>((_) => AuthService());
final firestoreServiceProvider = Provider<FirestoreService>((_) => FirestoreService());
final recommendationServiceProvider =
    Provider<RecommendationService>((_) => RecommendationService());

// ─── Firebase Auth stream ─────────────────────────────────────────────────────
final authStateProvider = StreamProvider<User?>(
    (_) => FirebaseAuth.instance.authStateChanges());

// ─── Current user model (Firestore) ──────────────────────────────────────────
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final auth = ref.watch(authStateProvider);
  return auth.when(
    data: (user) => user == null
        ? Stream.value(null)
        : ref.read(firestoreServiceProvider).userStream(user.uid),
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

// ─── Movie list providers (AutoDispose so they refetch on invalidate) ─────────
final trendingMoviesProvider = FutureProvider.autoDispose<List<Movie>>(
    (ref) => ref.read(tmdbApiProvider).getTrending());

final popularMoviesProvider = FutureProvider.autoDispose<List<Movie>>(
    (ref) => ref.read(tmdbApiProvider).getPopular());

final topRatedMoviesProvider = FutureProvider.autoDispose<List<Movie>>(
    (ref) => ref.read(tmdbApiProvider).getTopRated());

final actionMoviesProvider = FutureProvider.autoDispose<List<Movie>>(
    (ref) => ref.read(tmdbApiProvider).getActionMovies());

final comedyMoviesProvider = FutureProvider.autoDispose<List<Movie>>(
    (ref) => ref.read(tmdbApiProvider).getComedyMovies());

final horrorMoviesProvider = FutureProvider.autoDispose<List<Movie>>(
    (ref) => ref.read(tmdbApiProvider).getHorrorMovies());

final romanceMoviesProvider = FutureProvider.autoDispose<List<Movie>>(
    (ref) => ref.read(tmdbApiProvider).getRomanceMovies());

final scifiMoviesProvider = FutureProvider.autoDispose<List<Movie>>(
    (ref) => ref.read(tmdbApiProvider).getSciFiMovies());

final nowPlayingProvider = FutureProvider.autoDispose<List<Movie>>(
    (ref) => ref.read(tmdbApiProvider).getNowPlaying());

final bollywoodMoviesProvider = FutureProvider.autoDispose<List<Movie>>(
        (ref) => ref.read(tmdbApiProvider).getBollywoodMovies());

final pakistaniMoviesProvider = FutureProvider.autoDispose<List<Movie>>(
        (ref) => ref.read(tmdbApiProvider).getPakistaniMovies());

final koreanMoviesProvider = FutureProvider.autoDispose<List<Movie>>(
        (ref) => ref.read(tmdbApiProvider).getKoreanMovies());
final hollywoodMoviesProvider = FutureProvider.autoDispose<List<Movie>>(
        (ref) => ref.read(tmdbApiProvider).getHollywoodMovies());

final turkishMoviesProvider = FutureProvider.autoDispose<List<Movie>>(
        (ref) => ref.read(tmdbApiProvider).getTurkishMovies());

final japaneseMoviesProvider = FutureProvider.autoDispose<List<Movie>>(
        (ref) => ref.read(tmdbApiProvider).getJapaneseMovies());

final chineseMoviesProvider = FutureProvider.autoDispose<List<Movie>>(
        (ref) => ref.read(tmdbApiProvider).getChineseMovies());

final indonesianMoviesProvider = FutureProvider.autoDispose<List<Movie>>(
        (ref) => ref.read(tmdbApiProvider).getIndonesianMovies());

// ─── Movie details (family — keyed by movie ID) ───────────────────────────────
final movieDetailsProvider =
    FutureProvider.autoDispose.family<Movie, int>((ref, id) =>
        ref.read(tmdbApiProvider).getMovieDetails(id));

// ─── Featured movie (first trending item) ────────────────────────────────────
final featuredMovieProvider = Provider<AsyncValue<Movie?>>((ref) {
  final trending = ref.watch(trendingMoviesProvider);
  return trending.when(
    data: (movies) =>
        AsyncValue.data(movies.isNotEmpty ? movies.first : null),
    loading: () => const AsyncValue.loading(),
    error: AsyncValue.error,
  );
});

// ─── Search ───────────────────────────────────────────────────────────────────
class SearchState {
  final String query;
  final List<Movie> results;
  final bool isLoading;
  final String? error;

  const SearchState({
    this.query = '',
    this.results = const [],
    this.isLoading = false,
    this.error,
  });

  SearchState copyWith({
    String? query,
    List<Movie>? results,
    bool? isLoading,
    String? error,
  }) =>
      SearchState(
        query: query ?? this.query,
        results: results ?? this.results,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class SearchNotifier extends StateNotifier<SearchState> {
  final TmdbApi _api;
  SearchNotifier(this._api) : super(const SearchState());

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = const SearchState();
      return;
    }
    state = state.copyWith(query: query, isLoading: true, error: null);
    try {
      final results = await _api.searchMovies(query);
      state = state.copyWith(results: results, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clear() => state = const SearchState();
}

final searchProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  return SearchNotifier(ref.read(tmdbApiProvider));
});

// ─── AI Recommendations ───────────────────────────────────────────────────────
class RecommendationState {
  final String? movieTitle;
  final List<Movie> recommendations;
  final bool isLoading;
  final String? error;
  final String? message;

  const RecommendationState({
    this.movieTitle,
    this.recommendations = const [],
    this.isLoading = false,
    this.error,
    this.message,
  });

  RecommendationState copyWith({
    String? movieTitle,
    List<Movie>? recommendations,
    bool? isLoading,
    String? error,
    String? message,
  }) =>
      RecommendationState(
        movieTitle: movieTitle ?? this.movieTitle,
        recommendations: recommendations ?? this.recommendations,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        message: message,
      );
}

class RecommendationNotifier extends StateNotifier<RecommendationState> {
  final RecommendationService _svc;
  final TmdbApi _tmdb;
  RecommendationNotifier(this._svc, this._tmdb)
      : super(const RecommendationState());

  Future<void> getRecommendations(String title) async {
    if (title.trim().isEmpty) return;
    state = state.copyWith(
        movieTitle: title, isLoading: true, error: null, message: null);

    try {
      // 1️⃣ Try ML backend
      final result = await _svc.getRecommendations(title);
      if (result.movies.isNotEmpty) {
        state = state.copyWith(
          recommendations: result.movies,
          isLoading: false,
          message: result.isFromCache ? 'Served from cache' : result.message,
        );
        return;
      }

      // 2️⃣ Fallback — TMDB similar movies
      final search = await _tmdb.searchMovies(title);
      if (search.isNotEmpty) {
        final similar = await _tmdb.getSimilarMovies(search.first.id);
        state = state.copyWith(
          recommendations: similar,
          isLoading: false,
          message: 'ML backend offline — showing TMDB suggestions',
        );
      } else {
        state = state.copyWith(
          recommendations: [],
          isLoading: false,
          message: result.message ?? 'No results found for "$title".',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clear() => state = const RecommendationState();
}

final recommendationNotifierProvider =
    StateNotifierProvider<RecommendationNotifier, RecommendationState>((ref) {
  return RecommendationNotifier(
    ref.read(recommendationServiceProvider),
    ref.read(tmdbApiProvider),
  );
});

// ─── Favorites & Watchlist (real-time Firestore streams) ─────────────────────
final favoritesProvider = StreamProvider<List<Movie>>((ref) {
  final auth = ref.watch(authStateProvider);
  return auth.when(
    data: (user) => user == null
        ? Stream.value([])
        : ref.read(firestoreServiceProvider).favoritesStream(user.uid),
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

final watchlistProvider = StreamProvider<List<Movie>>((ref) {
  final auth = ref.watch(authStateProvider);
  return auth.when(
    data: (user) => user == null
        ? Stream.value([])
        : ref.read(firestoreServiceProvider).watchlistStream(user.uid),
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// ─── Bottom nav index ─────────────────────────────────────────────────────────
final navIndexProvider = StateProvider<int>((_) => 0);
