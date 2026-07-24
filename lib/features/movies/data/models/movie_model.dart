import 'package:popcorn_movie_tracker/features/movies/domain/entities/movie.dart';

class MovieModel {
  static Movie fromJson(Map<String, dynamic> json) {
    final credits = json['credits'] as Map<String, dynamic>?;
    final videos = json['videos'] as Map<String, dynamic>?;
    final similar = json['similar'] as Map<String, dynamic>?;
    final videoResults = (videos?['results'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        const [];
    String? trailerKey;
    for (final video in videoResults) {
      if (video['site'] == 'YouTube' &&
          (video['type'] == 'Trailer' || video['type'] == 'Teaser')) {
        trailerKey = video['key'] as String?;
        break;
      }
    }

    return Movie(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? json['title'] as String
          : 'Untitled',
      overview: json['overview'] as String? ?? '',
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      releaseDate: json['release_date'] as String? ?? '',
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0,
      genreIds: (json['genre_ids'] as List?)
              ?.whereType<num>()
              .map((e) => e.toInt())
              .toList() ??
          const [],
      popularity: (json['popularity'] as num?)?.toDouble() ?? 0,
      runtime: (json['runtime'] as num?)?.toInt(),
      budget: (json['budget'] as num?)?.toInt(),
      revenue: (json['revenue'] as num?)?.toInt(),
      voteCount: (json['vote_count'] as num?)?.toInt(),
      originalLanguage: json['original_language'] as String?,
      genres: (json['genres'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map((e) => e['name'] as String? ?? '')
              .where((e) => e.isNotEmpty)
              .toList() ??
          const [],
      cast: (credits?['cast'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .take(12)
              .map((e) => CastMember(
                  name: e['name'] as String? ?? '',
                  profilePath: e['profile_path'] as String?))
              .toList() ??
          const [],
      trailerKey: trailerKey,
      similar: (similar?['results'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .take(12)
              .map(MovieModel.fromJson)
              .toList() ??
          const [],
    );
  }
}
