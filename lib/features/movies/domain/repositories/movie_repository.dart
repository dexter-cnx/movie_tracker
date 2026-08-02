import 'package:popcorn_movie_tracker/features/movies/domain/entities/movie.dart';
import 'package:popcorn_movie_tracker/features/movies/domain/entities/movie_load_result.dart';
import 'package:popcorn_movie_tracker/features/movies/domain/entities/paged_movies.dart';

abstract interface class MovieRepository {
  Future<List<Movie>> getPopular(String language);
  Future<List<Movie>> getTrending(String language);
  Future<MovieLoadResult> getTrendingFeed(
    String language, {
    bool forceRefresh = false,
  });
  Future<List<Movie>> getTopRated(String language);
  Future<List<Movie>> getUpcoming(String language);
  Future<List<Movie>> getNowPlaying(String language);
  Future<Movie> getDetails(int id, String language);
  Future<List<Movie>> search(String query, String language);
  Future<PagedMovies> searchPage(String query, String language, int page);
  Future<List<Genre>> getGenres(String language);
  Future<List<Movie>> discoverByGenre(int? genreId, String language);
}

class Genre {
  const Genre(this.id, this.name);
  final int id;
  final String name;
}
