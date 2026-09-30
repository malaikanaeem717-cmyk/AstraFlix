// lib/utils/app_constants.dart
// Global constants used throughout AstraFlix

class AppConstants {
  // App Info
  static const String appName = 'AstraFlix';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'AI Movie Recommendations';

  // SharedPreferences Keys
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keyThemeMode = 'theme_mode';
  static const String keyUserUid = 'user_uid';

  // Firestore Collections
  static const String colUsers = 'users';
  static const String colFavorites = 'favorites';
  static const String colWatchlist = 'watchlist';

  // Animations
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animMedium = Duration(milliseconds: 350);
  static const Duration animSlow = Duration(milliseconds: 500);

  // Pagination
  static const int pageSize = 20;

  // Image placeholders
  static const String placeholderPoster =
      'https://via.placeholder.com/300x450/1A1A1A/737373?text=No+Poster';

  static const String placeholderBackdrop =
      'https://via.placeholder.com/1280x720/1A1A1A/737373?text=No+Image';
}

// Validation helpers
class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    if (value.trim().length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value != original) return 'Passwords do not match';
    return null;
  }
}

// Number formatters
class AppFormatters {
  static String compactNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  static String ratingPercent(double rating) {
    return '${((rating / 10) * 100).round()}%';
  }
}
