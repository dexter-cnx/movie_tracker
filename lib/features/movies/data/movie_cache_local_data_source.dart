import 'package:hive/hive.dart';
import 'package:popcorn_movie_tracker/features/movies/domain/entities/movie.dart';

class CachedMovieList {
  const CachedMovieList({required this.movies, required this.cachedAt});

  final List<Movie> movies;
  final DateTime cachedAt;

  bool isFresh(Duration ttl, DateTime now) => now.difference(cachedAt) <= ttl;
}

class MovieCacheLocalDataSource {
  MovieCacheLocalDataSource(this.box);

  static const boxName = 'movie_cache';

  final Box<Map> box;

  CachedMovieList? read(String key) {
    final raw = box.get(key);
    if (raw == null) return null;
    final cachedAtValue = raw['cachedAt'];
    final items = raw['items'];
    if (cachedAtValue is! String || items is! List) return null;

    try {
      return CachedMovieList(
        cachedAt: DateTime.parse(cachedAtValue),
        movies: items
            .whereType<Map>()
            .map((item) => _movieFromMap(item))
            .toList(growable: false),
      );
    } on Object {
      return null;
    }
  }

  Future<void> write(String key, List<Movie> movies, DateTime cachedAt) {
    return box.put(key, <String, dynamic>{
      'cachedAt': cachedAt.toIso8601String(),
      'items': movies.map(_movieToMap).toList(growable: false),
    });
  }

  Future<void> clear() async {
    await box.clear();
  }

  static Map<String, dynamic> _movieToMap(Movie movie) => <String, dynamic>{
        'id': movie.id,
        'title': movie.title,
        'overview': movie.overview,
        'posterPath': movie.posterPath,
        'backdropPath': movie.backdropPath,
        'releaseDate': movie.releaseDate,
        'voteAverage': movie.voteAverage,
        'genreIds': movie.genreIds,
        'popularity': movie.popularity,
        'runtime': movie.runtime,
        'budget': movie.budget,
        'revenue': movie.revenue,
        'voteCount': movie.voteCount,
        'originalLanguage': movie.originalLanguage,
        'genres': movie.genres,
        'cast': movie.cast
            .map((member) => <String, dynamic>{
                  'name': member.name,
                  'profilePath': member.profilePath,
                })
            .toList(growable: false),
        'trailerKey': movie.trailerKey,
      };

  static Movie _movieFromMap(Map<dynamic, dynamic> map) => Movie(
        id: (map['id'] as num?)?.toInt() ?? 0,
        title: map['title'] as String? ?? 'Untitled',
        overview: map['overview'] as String? ?? '',
        posterPath: map['posterPath'] as String?,
        backdropPath: map['backdropPath'] as String?,
        releaseDate: map['releaseDate'] as String? ?? '',
        voteAverage: (map['voteAverage'] as num?)?.toDouble() ?? 0,
        genreIds: (map['genreIds'] as List?)
                ?.whereType<num>()
                .map((value) => value.toInt())
                .toList(growable: false) ??
            const [],
        popularity: (map['popularity'] as num?)?.toDouble() ?? 0,
        runtime: (map['runtime'] as num?)?.toInt(),
        budget: (map['budget'] as num?)?.toInt(),
        revenue: (map['revenue'] as num?)?.toInt(),
        voteCount: (map['voteCount'] as num?)?.toInt(),
        originalLanguage: map['originalLanguage'] as String?,
        genres:
            (map['genres'] as List?)?.whereType<String>().toList() ?? const [],
        cast: (map['cast'] as List?)
                ?.whereType<Map>()
                .map(
                  (member) => CastMember(
                    name: member['name'] as String? ?? '',
                    profilePath: member['profilePath'] as String?,
                  ),
                )
                .toList(growable: false) ??
            const [],
        trailerKey: map['trailerKey'] as String?,
      );
}
