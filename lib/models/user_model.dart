// lib/models/user_model.dart
// User model synced with Firebase Auth and Firestore

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final List<int> favoriteIds;
  final List<int> watchlistIds;
  final List<String> searchHistory;
  final List<int> recentlyViewed;
  final Map<int, double> ratings;
  final UserStats stats;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.createdAt,
    this.lastLoginAt,
    this.favoriteIds = const [],
    this.watchlistIds = const [],
    this.searchHistory = const [],
    this.recentlyViewed = const [],
    this.ratings = const {},
    this.stats = const UserStats(),
  });

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': createdAt?.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'favoriteIds': favoriteIds,
      'watchlistIds': watchlistIds,
      'searchHistory': searchHistory.take(20).toList(), // Keep last 20
      'recentlyViewed': recentlyViewed.take(50).toList(), // Keep last 50
      'ratings': ratings.map((k, v) => MapEntry(k.toString(), v)),
      'stats': stats.toMap(),
    };
  }

  // Factory from Firestore document
  factory UserModel.fromFirestore(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? 'AstraFlix User',
      photoUrl: data['photoUrl'],
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'])
          : null,
      lastLoginAt: data['lastLoginAt'] != null
          ? DateTime.tryParse(data['lastLoginAt'])
          : null,
      favoriteIds: List<int>.from(data['favoriteIds'] ?? []),
      watchlistIds: List<int>.from(data['watchlistIds'] ?? []),
      searchHistory: List<String>.from(data['searchHistory'] ?? []),
      recentlyViewed: List<int>.from(data['recentlyViewed'] ?? []),
      ratings: (data['ratings'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(int.tryParse(k) ?? 0, (v as num).toDouble())) ??
          {},
      stats: data['stats'] != null
          ? UserStats.fromMap(data['stats'])
          : const UserStats(),
    );
  }

  // CopyWith for immutable updates
  UserModel copyWith({
    String? displayName,
    String? photoUrl,
    DateTime? lastLoginAt,
    List<int>? favoriteIds,
    List<int>? watchlistIds,
    List<String>? searchHistory,
    List<int>? recentlyViewed,
    Map<int, double>? ratings,
    UserStats? stats,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      favoriteIds: favoriteIds ?? this.favoriteIds,
      watchlistIds: watchlistIds ?? this.watchlistIds,
      searchHistory: searchHistory ?? this.searchHistory,
      recentlyViewed: recentlyViewed ?? this.recentlyViewed,
      ratings: ratings ?? this.ratings,
      stats: stats ?? this.stats,
    );
  }

  // First name for greeting
  String get firstName =>
      displayName.split(' ').first.isNotEmpty ? displayName.split(' ').first : 'User';

  // Avatar initials fallback
  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }
}

// User statistics model
class UserStats {
  final int moviesWatched;
  final int moviesRated;
  final int moviesFavorited;
  final int hoursWatched;

  const UserStats({
    this.moviesWatched = 0,
    this.moviesRated = 0,
    this.moviesFavorited = 0,
    this.hoursWatched = 0,
  });

  Map<String, dynamic> toMap() => {
    'moviesWatched': moviesWatched,
    'moviesRated': moviesRated,
    'moviesFavorited': moviesFavorited,
    'hoursWatched': hoursWatched,
  };

  factory UserStats.fromMap(Map<String, dynamic> data) => UserStats(
    moviesWatched: data['moviesWatched'] ?? 0,
    moviesRated: data['moviesRated'] ?? 0,
    moviesFavorited: data['moviesFavorited'] ?? 0,
    hoursWatched: data['hoursWatched'] ?? 0,
  );

  UserStats copyWith({
    int? moviesWatched,
    int? moviesRated,
    int? moviesFavorited,
    int? hoursWatched,
  }) =>
      UserStats(
        moviesWatched: moviesWatched ?? this.moviesWatched,
        moviesRated: moviesRated ?? this.moviesRated,
        moviesFavorited: moviesFavorited ?? this.moviesFavorited,
        hoursWatched: hoursWatched ?? this.hoursWatched,
      );
}
