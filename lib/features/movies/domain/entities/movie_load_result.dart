import 'package:popcorn_movie_tracker/core/errors/app_failure.dart';
import 'package:popcorn_movie_tracker/features/movies/domain/entities/movie.dart';

enum MovieDataSource { network, freshCache, staleCache, mock }

class MovieLoadResult {
  const MovieLoadResult({
    required this.movies,
    required this.source,
    this.failure,
  });

  final List<Movie> movies;
  final MovieDataSource source;
  final AppFailure? failure;

  bool get isOffline =>
      source == MovieDataSource.staleCache || source == MovieDataSource.mock;
}
