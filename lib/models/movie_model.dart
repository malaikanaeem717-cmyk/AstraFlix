// lib/models/movie_model.dart
// Data model representing a movie from TMDB API

class Movie {
  final int id;
  final String title;
  final String? originalTitle;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final double voteAverage;
  final int voteCount;
  final String? releaseDate;
  final List<int> genreIds;
  final List<Genre> genres;
  final double popularity;
  final bool adult;
  final String? originalLanguage;
  final int? runtime;
  final String? status;
  final String? tagline;
  final List<CastMember> cast;
  final List<Video> videos;
  final List<Movie> similar;
  bool isFavorite;
  bool isInWatchlist;
  double? userRating;

  Movie({
    required this.id,
    required this.title,
    this.originalTitle,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.voteAverage = 0.0,
    this.voteCount = 0,
    this.releaseDate,
    this.genreIds = const [],
    this.genres = const [],
    this.popularity = 0.0,
    this.adult = false,
    this.originalLanguage,
    this.runtime,
    this.status,
    this.tagline,
    this.cast = const [],
    this.videos = const [],
    this.similar = const [],
    this.isFavorite = false,
    this.isInWatchlist = false,
    this.userRating,
  });

  // Full poster URL using TMDB image base
  String get posterUrl =>
      posterPath != null ? 'https://image.tmdb.org/t/p/w500$posterPath' : '';

  // High-res poster
  String get posterUrlHD =>
      posterPath != null ? 'https://image.tmdb.org/t/p/original$posterPath' : '';

  // Backdrop URL
  String get backdropUrl =>
      backdropPath != null ? 'https://image.tmdb.org/t/p/w1280$backdropPath' : '';

  // Year extracted from release date
  String get year => releaseDate?.length != null && releaseDate!.length >= 4
      ? releaseDate!.substring(0, 4)
      : '';

  // Formatted rating out of 10
  String get ratingFormatted => voteAverage.toStringAsFixed(1);

  // Rating out of 5 (for star display)
  double get ratingOutOf5 => voteAverage / 2;

  // Formatted runtime
  String get runtimeFormatted {
    if (runtime == null || runtime == 0) return '';
    final hours = runtime! ~/ 60;
    final minutes = runtime! % 60;
    if (hours == 0) return '${minutes}m';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  // First genre name
  String get mainGenre =>
      genres.isNotEmpty ? genres.first.name : (genreIds.isNotEmpty ? '' : '');

  // Comma-separated genre names
  String get genreNames => genres.map((g) => g.name).join(', ');

  // Factory from TMDB API JSON (list endpoint)
  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] ?? 0,
      title: json['title'] ?? json['name'] ?? '',
      originalTitle: json['original_title'] ?? json['original_name'],
      overview: json['overview'],
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      voteAverage: (json['vote_average'] ?? 0.0).toDouble(),
      voteCount: json['vote_count'] ?? 0,
      releaseDate: json['release_date'] ?? json['first_air_date'],
      genreIds: List<int>.from(json['genre_ids'] ?? []),
      genres: (json['genres'] as List<dynamic>?)
              ?.map((g) => Genre.fromJson(g))
              .toList() ?? [],
      popularity: (json['popularity'] ?? 0.0).toDouble(),
      adult: json['adult'] ?? false,
      originalLanguage: json['original_language'],
      runtime: json['runtime'],
      status: json['status'],
      tagline: json['tagline'],
      cast: (json['credits']?['cast'] as List<dynamic>?)
              ?.map((c) => CastMember.fromJson(c))
              .toList() ?? [],
      videos: (json['videos']?['results'] as List<dynamic>?)
              ?.where((v) => v['site'] == 'YouTube')
              .map((v) => Video.fromJson(v))
              .toList() ?? [],
      similar: (json['similar']?['results'] as List<dynamic>?)
              ?.map((m) => Movie.fromJson(m))
              .toList() ?? [],
    );
  }

  // Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'posterPath': posterPath,
      'backdropPath': backdropPath,
      'voteAverage': voteAverage,
      'releaseDate': releaseDate,
      'overview': overview,
      'genreIds': genreIds,
    };
  }

  // Create from Firestore map (minimal data stored)
  factory Movie.fromFirestore(Map<String, dynamic> data) {
    return Movie(
      id: data['id'] ?? 0,
      title: data['title'] ?? '',
      posterPath: data['posterPath'],
      backdropPath: data['backdropPath'],
      voteAverage: (data['voteAverage'] ?? 0.0).toDouble(),
      releaseDate: data['releaseDate'],
      overview: data['overview'],
      genreIds: List<int>.from(data['genreIds'] ?? []),
    );
  }

  // CopyWith for state updates
  Movie copyWith({
    bool? isFavorite,
    bool? isInWatchlist,
    double? userRating,
    List<CastMember>? cast,
    List<Video>? videos,
    List<Movie>? similar,
    List<Genre>? genres,
    int? runtime,
    String? status,
    String? tagline,
  }) {
    return Movie(
      id: id,
      title: title,
      originalTitle: originalTitle,
      overview: overview,
      posterPath: posterPath,
      backdropPath: backdropPath,
      voteAverage: voteAverage,
      voteCount: voteCount,
      releaseDate: releaseDate,
      genreIds: genreIds,
      genres: genres ?? this.genres,
      popularity: popularity,
      adult: adult,
      originalLanguage: originalLanguage,
      runtime: runtime ?? this.runtime,
      status: status ?? this.status,
      tagline: tagline ?? this.tagline,
      cast: cast ?? this.cast,
      videos: videos ?? this.videos,
      similar: similar ?? this.similar,
      isFavorite: isFavorite ?? this.isFavorite,
      isInWatchlist: isInWatchlist ?? this.isInWatchlist,
      userRating: userRating ?? this.userRating,
    );
  }
}

// Genre model
class Genre {
  final int id;
  final String name;

  const Genre({required this.id, required this.name});

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(id: json['id'] ?? 0, name: json['name'] ?? '');
  }

  // Static genre map for offline use (from TMDB)
  static const Map<int, String> genreMap = {
    28: 'Action',
    12: 'Adventure',
    16: 'Animation',
    35: 'Comedy',
    80: 'Crime',
    99: 'Documentary',
    18: 'Drama',
    10751: 'Family',
    14: 'Fantasy',
    36: 'History',
    27: 'Horror',
    10402: 'Music',
    9648: 'Mystery',
    10749: 'Romance',
    878: 'Sci-Fi',
    10770: 'TV Movie',
    53: 'Thriller',
    10752: 'War',
    37: 'Western',
  };

  static String nameFromId(int id) => genreMap[id] ?? 'Unknown';
}

// Cast Member model
class CastMember {
  final int id;
  final String name;
  final String? character;
  final String? profilePath;
  final int order;

  const CastMember({
    required this.id,
    required this.name,
    this.character,
    this.profilePath,
    this.order = 0,
  });

  String get profileUrl =>
      profilePath != null ? 'https://image.tmdb.org/t/p/w185$profilePath' : '';

  factory CastMember.fromJson(Map<String, dynamic> json) {
    return CastMember(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      character: json['character'],
      profilePath: json['profile_path'],
      order: json['order'] ?? 0,
    );
  }
}

// Video/Trailer model
class Video {
  final String id;
  final String key;
  final String name;
  final String site;
  final String type;
  final bool official;

  const Video({
    required this.id,
    required this.key,
    required this.name,
    required this.site,
    required this.type,
    this.official = false,
  });

  String get youtubeUrl => 'https://www.youtube.com/watch?v=$key';
  String get youtubeThumbnail => 'https://img.youtube.com/vi/$key/hqdefault.jpg';

  bool get isTrailer => type == 'Trailer';

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['id'] ?? '',
      key: json['key'] ?? '',
      name: json['name'] ?? '',
      site: json['site'] ?? '',
      type: json['type'] ?? '',
      official: json['official'] ?? false,
    );
  }
}
