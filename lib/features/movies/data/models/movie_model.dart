import 'package:popcorn_movie_tracker/features/movies/data/models/tmdb_dto.dart';
import 'package:popcorn_movie_tracker/features/movies/domain/entities/movie.dart';

/// Backward-compatible facade for callers/tests that still use the previous
/// `MovieModel.fromJson` API. JSON parsing is now owned by Freezed DTOs.
class MovieModel {
  const MovieModel._();

  static Movie fromJson(Map<String, dynamic> json) =>
      TmdbMovieDto.fromJson(json).toDomain();
}
