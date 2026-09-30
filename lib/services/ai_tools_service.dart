// lib/services/ai_tools_service.dart
// Defines the "tools" Astra (the AI chatbot) can call — turning it from a
// plain chatbot into an agent that can search real TMDB data and take real
// actions (add to watchlist/favorites) on the signed-in user's behalf,
// instead of only answering from its training data.
//
// Tool-calling is currently wired up for the direct Groq path only (see
// ai_chat_service.dart). The Gemini fallback and the optional backend proxy
// answer as a plain conversational assistant, without tool access — that's
// a deliberate scope decision, not an oversight.

import '../api/tmdb_api.dart';
import '../models/movie_model.dart';
import 'firestore_service.dart';

class AiToolsService {
  final String uid;
  final TmdbApi _tmdb;
  final FirestoreService _firestore;

  AiToolsService({
    required this.uid,
    TmdbApi? tmdb,
    FirestoreService? firestore,
  })  : _tmdb = tmdb ?? TmdbApi(),
        _firestore = firestore ?? FirestoreService();

  static const List<Map<String, dynamic>> toolSchemas = [
    {
      'type': 'function',
      'function': {
        'name': 'search_movies',
        'description':
        'Search for movies by title, actor, or theme using live TMDB data. '
            'Use this whenever the user asks to find a specific movie, or '
            'movies matching a description — never guess titles from memory '
            'when this tool can look them up.',
        'parameters': {
          'type': 'object',
          'properties': {
            'query': {
              'type': 'string',
              'description': 'Search text, e.g. a movie title or theme.'
            }
          },
          'required': ['query'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'get_similar_movies',
        'description':
        'Get movies similar to a given movie, by its TMDB movie ID. '
            'Call search_movies first if you only have a title, to get the ID.',
        'parameters': {
          'type': 'object',
          'properties': {
            'movie_id': {'type': 'integer', 'description': 'The TMDB movie ID.'}
          },
          'required': ['movie_id'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'get_trending_movies',
        'description': 'Get the current trending movies this week, live from TMDB.',
        'parameters': {'type': 'object', 'properties': {}},
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'add_to_watchlist',
        'description':
        "Add a movie to the signed-in user's watchlist, by its TMDB movie ID. "
            'Only call this when the user explicitly asks to save/add a movie '
            'to their watchlist.',
        'parameters': {
          'type': 'object',
          'properties': {
            'movie_id': {'type': 'integer', 'description': 'The TMDB movie ID to add.'}
          },
          'required': ['movie_id'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'add_to_favorites',
        'description':
        "Add a movie to the signed-in user's favorites, by its TMDB movie ID. "
            'Only call this when the user explicitly asks to favorite/like a movie.',
        'parameters': {
          'type': 'object',
          'properties': {
            'movie_id': {'type': 'integer', 'description': 'The TMDB movie ID to add.'}
          },
          'required': ['movie_id'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'get_watchlist',
        'description': "Get the signed-in user's current watchlist, live from Firestore.",
        'parameters': {'type': 'object', 'properties': {}},
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'get_favorites',
        'description': "Get the signed-in user's favorited movies, live from Firestore.",
        'parameters': {'type': 'object', 'properties': {}},
      },
    },
  ];

  static const List<String> toolNames = [
    'search_movies',
    'get_similar_movies',
    'get_trending_movies',
    'add_to_watchlist',
    'add_to_favorites',
    'get_watchlist',
    'get_favorites',
  ];

  Future<Map<String, dynamic>> execute(String name, Map<String, dynamic> args) async {
    try {
      switch (name) {
        case 'search_movies':
          final query = (args['query'] ?? '').toString().trim();
          if (query.isEmpty) return {'error': 'No search query was given.'};
          final results = await _tmdb.searchMovies(query);
          if (results.isEmpty) return {'results': [], 'note': 'No movies found for that query.'};
          return {'results': results.take(8).map(_summarize).toList()};

        case 'get_similar_movies':
          final id = _asInt(args['movie_id']);
          if (id == null) return {'error': 'No valid movie_id was given.'};
          final results = await _tmdb.getSimilarMovies(id);
          return {'results': results.take(8).map(_summarize).toList()};

        case 'get_trending_movies':
          final results = await _tmdb.getTrending();
          return {'results': results.take(10).map(_summarize).toList()};

        case 'add_to_watchlist':
          final id = _asInt(args['movie_id']);
          if (id == null) return {'error': 'No valid movie_id was given.'};
          final movie = await _tmdb.getMovieDetails(id);
          await _firestore.addToWatchlist(uid, movie);
          return {'success': true, 'added': movie.title, 'movie_id': movie.id};

        case 'add_to_favorites':
          final id = _asInt(args['movie_id']);
          if (id == null) return {'error': 'No valid movie_id was given.'};
          final movie = await _tmdb.getMovieDetails(id);
          await _firestore.addToFavorites(uid, movie);
          return {'success': true, 'added': movie.title, 'movie_id': movie.id};

        case 'get_watchlist':
          final list = await _firestore.watchlistStream(uid).first;
          if (list.isEmpty) return {'results': [], 'note': "The user's watchlist is empty."};
          return {'results': list.take(15).map(_summarize).toList()};

        case 'get_favorites':
          final list = await _firestore.favoritesStream(uid).first;
          if (list.isEmpty) return {'results': [], 'note': "The user hasn't favorited any movies yet."};
          return {'results': list.take(15).map(_summarize).toList()};

        default:
          return {'error': 'Unknown tool: $name'};
      }
    } catch (e) {
      return {'error': 'That failed: ${e.toString()}'};
    }
  }

  static String statusLabel(String toolName) {
    switch (toolName) {
      case 'search_movies':
        return '🔍 Searching movies…';
      case 'get_similar_movies':
        return '🎬 Finding similar movies…';
      case 'get_trending_movies':
        return "🔥 Checking what's trending…";
      case 'add_to_watchlist':
        return '📌 Adding to your watchlist…';
      case 'add_to_favorites':
        return '❤️ Adding to your favorites…';
      case 'get_watchlist':
        return '📋 Checking your watchlist…';
      case 'get_favorites':
        return '❤️ Checking your favorites…';
      default:
        return '⚙️ Working on it…';
    }
  }

  int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  Map<String, dynamic> _summarize(Movie m) => {
    'id': m.id,
    'title': m.title,
    'year': (m.releaseDate != null && m.releaseDate!.length >= 4)
        ? m.releaseDate!.substring(0, 4)
        : null,
    'rating': m.voteAverage,
    'overview': m.overview,
    'posterPath': m.posterPath,
  };
}