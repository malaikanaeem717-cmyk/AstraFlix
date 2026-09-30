

class ApiConstants {
  // ─── TMDB Configuration ───────────────────────────────────────────────────
  // Keys are injected at BUILD TIME via --dart-define-from-file=env.local.json,
  // never hardcoded and never shipped as plaintext inside the source. The
  // NAME passed to String.fromEnvironment must match the JSON key exactly.
  static const String tmdbApiKey = String.fromEnvironment('TMDB_API_KEY');
  static const String tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const String tmdbImageBase = 'https://image.tmdb.org/t/p';
  static const String youtubeApiKey = String.fromEnvironment('YOUTUBE_API_KEY');

  // TMDB Image Sizes
  static const String posterSmall = '$tmdbImageBase/w185';
  static const String posterMedium = '$tmdbImageBase/w342';
  static const String posterLarge = '$tmdbImageBase/w500';
  static const String posterOriginal = '$tmdbImageBase/original';
  static const String backdropSmall = '$tmdbImageBase/w300';
  static const String backdropLarge = '$tmdbImageBase/w1280';
  static const String backdropOriginal = '$tmdbImageBase/original';
  static const String profileSmall = '$tmdbImageBase/w185';

  // ─── AstraFlix ML Recommendation Backend ──────────────────────────────────
  static const String recommendationBaseUrl = String.fromEnvironment(
    'RECOMMENDATION_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static const String recommendEndpoint = '/recommend';

  // ─── AstraFlix AI Chatbot (Groq — free, OpenAI-compatible) ────────────────
  // Get a free key at https://console.groq.com/keys (no credit card needed)
  // and run with: flutter run --dart-define-from-file=env.local.json
  //
  // ⚠️ Web builds ship this key readable in the browser's Network tab no
  // matter what (dart-define is compiled into the client). Before you put
  // this online, route AI chat through a small backend proxy that holds the
  // real key server-side — see /backend/proxy_server.py in this project.
  static const String groqApiKey = String.fromEnvironment('GROQ_API_KEY');
  // If AI_PROXY_BASE_URL is set, ai_chat_service.dart calls YOUR proxy
  // instead of Groq directly, so the real key never reaches the client.
  static const String aiProxyBaseUrl = String.fromEnvironment('AI_PROXY_BASE_URL');
  static const String groqBaseUrl = 'https://api.groq.com/openai/v1';
  static const String groqChatEndpoint = '/chat/completions';
  // Fast + free + very capable. If GROQ_MODEL is set it's tried first;
  // either way, the built-in candidate list below is tried automatically
  // after it, so you never have to hand-edit a model name when Groq
  // deprecates one — the app just moves to the next candidate itself.
  static const String groqModel = String.fromEnvironment('GROQ_MODEL', defaultValue: '');
  static const List<String> _groqModelFallbacks = [
    'openai/gpt-oss-120b',
    'openai/gpt-oss-20b',
    'qwen/qwen3.6-27b',
  ];
  static List<String> get groqModelCandidates =>
      groqModel.isNotEmpty ? [groqModel, ..._groqModelFallbacks] : _groqModelFallbacks;
  static const int chatRequestTimeoutSeconds = 45;
  // Shorter timeout used only for the Groq leg when a Gemini fallback is
  // configured — fail fast over to Gemini instead of making the user wait
  // through the full timeout twice.
  static const int groqFallbackTimeoutSeconds = 12;
  // Same idea for the Gemini leg — bounds total worst-case wait time
  // (Groq attempt + Gemini attempt) to roughly 30s instead of up to ~90s.
  static const int geminiFallbackTimeoutSeconds = 15;
  static const int chatHistoryContextLimit = 20; // last N messages sent as context

  // ─── AI Chatbot fallback — Gemini ──────────────────────────────────────────
  // If GEMINI_API_KEY is set, the chat service tries Groq first and — on
  // ANY failure (deprecated/renamed model, rate limit, timeout, outage) —
  // automatically retries with Gemini instead of showing the user an error.
  // Free key: https://aistudio.google.com/apikey
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';
  static const String geminiModel = String.fromEnvironment('GEMINI_MODEL', defaultValue: '');
  static const List<String> _geminiModelFallbacks = [
    'gemini-3.8-flash',
    'gemini-3.5-flash',
  ];
  static List<String> get geminiModelCandidates =>
      geminiModel.isNotEmpty ? [geminiModel, ..._geminiModelFallbacks] : _geminiModelFallbacks;
  static bool get hasGeminiKey => geminiApiKey.isNotEmpty;

  // ─── Config validity helpers ───────────────────────────────────────────────
  // Used at startup / in the UI to show a clear "missing key" message instead
  // of a confusing 401 deep inside a network call.
  static bool get hasTmdbKey => tmdbApiKey.isNotEmpty;
  static bool get hasGroqKey => groqApiKey.isNotEmpty || aiProxyBaseUrl.isNotEmpty;
  static bool get usesAiProxy => aiProxyBaseUrl.isNotEmpty;

  // ─── Cloudinary (profile photo uploads) ───────────────────────────────────
  // Free, unsigned-upload alternative to Firebase Storage — no Blaze/billing
  // plan needed. Get a free cloud name + unsigned upload preset at
  // https://cloudinary.com (Settings → Upload → Upload presets → Add,
  // Signing Mode: Unsigned).
  static const String cloudinaryCloudName = String.fromEnvironment('CLOUDINARY_CLOUD_NAME');
  static const String cloudinaryUploadPreset = String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET');
  static bool get hasCloudinaryConfig => cloudinaryCloudName.isNotEmpty && cloudinaryUploadPreset.isNotEmpty;
  static String get cloudinaryUploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload';

  // ─── TMDB Endpoints ───────────────────────────────────────────────────────
  static const String trending = '/trending/movie/week';
  static const String trendingDay = '/trending/movie/day';

  static const String popular = '/movie/popular';
  static const String topRated = '/movie/top_rated';
  static const String upcoming = '/movie/upcoming';
  static const String nowPlaying = '/movie/now_playing';

  static String movieDetails(int id) =>
      '/movie/$id?append_to_response=credits,videos,similar,recommendations';

  static const String searchMovies = '/search/movie';
  static const String searchMulti = '/search/multi';

  static const String discover = '/movie/discover';
  static String discoverByGenre(int genreId) =>
      '/discover/movie?with_genres=$genreId';

  static const String genreList = '/genre/movie/list';

  // ─── Genre IDs ────────────────────────────────────────────────────────────
  static const int genreAction = 28;
  static const int genreComedy = 35;
  static const int genreHorror = 27;
  static const int genreRomance = 10749;
  static const int genreSciFi = 878;
  static const int genreDrama = 18;
  static const int genreThriller = 53;
  static const int genreAnimation = 16;
  static const int genreCrime = 80;
  static const int genreDocumentary = 99;
  static const int genreAdventure = 12;
  static const int genreFantasy = 14;

  // ─── Request Timeouts ─────────────────────────────────────────────────────
  static const int connectTimeout = 10000;
  static const int receiveTimeout = 15000;

  // ─── Pagination ───────────────────────────────────────────────────────────
  static const int defaultPageSize = 20;
  static const int maxPages = 500;

  // ─── Cache Duration ───────────────────────────────────────────────────────
  static const Duration movieCacheDuration = Duration(hours: 2);
  static const Duration trendingCacheDuration = Duration(hours: 1);
  static const Duration searchCacheDuration = Duration(minutes: 30);

  static String watchProviders(int movieId) => '/movie/$movieId/watch/providers';

  // ─── Language codes ────────────────────────────────────────────────────────
  static const String langEnglish = 'en';
  static const String langHindi = 'hi';
  static const String langUrdu = 'ur';
  static const String langKorean = 'ko';
  static const String langTurkish = 'tr';
  static const String langJapanese = 'ja';
  static const String langChinese = 'zh';
  static const String langIndonesian = 'id';
}