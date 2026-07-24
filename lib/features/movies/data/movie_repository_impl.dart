import 'package:popcorn_movie_tracker/features/movies/data/mock_movies.dart';
import 'package:popcorn_movie_tracker/features/movies/data/tmdb_remote_data_source.dart';
import 'package:popcorn_movie_tracker/features/movies/domain/entities/movie.dart';
import 'package:popcorn_movie_tracker/features/movies/domain/repositories/movie_repository.dart';

class MovieRepositoryImpl implements MovieRepository {
  MovieRepositoryImpl(this.remote);
  final TmdbRemoteDataSource remote;

  Future<T> _fallback<T>(Future<T> Function() action, T fallback) async {
    try {
      return await action();
    } catch (_) {
      return fallback;
    }
  }

  @override
  Future<List<Movie>> getPopular(String l) =>
      _fallback(() => remote.popular(l), mockMovies);
  @override
  Future<List<Movie>> getTrending(String l) =>
      _fallback(() => remote.trending(l), mockMovies);
  @override
  Future<List<Movie>> getTopRated(String l) => _fallback(
      () => remote.topRated(l),
      [...mockMovies]..sort((a, b) => b.voteAverage.compareTo(a.voteAverage)));
  @override
  Future<List<Movie>> getUpcoming(String l) =>
      _fallback(() => remote.upcoming(l), mockMovies.reversed.toList());
  @override
  Future<List<Movie>> getNowPlaying(String l) =>
      _fallback(() => remote.nowPlaying(l), mockMovies.take(6).toList());
  @override
  Future<List<Movie>> search(String q, String l) => _fallback(
      () => remote.search(q, l),
      mockMovies
          .where((m) => m.title.toLowerCase().contains(q.toLowerCase()))
          .toList());
  @override
  Future<List<Genre>> getGenres(String l) =>
      _fallback(() => remote.genres(l), const [
        Genre(28, 'Action'),
        Genre(35, 'Comedy'),
        Genre(18, 'Drama'),
        Genre(878, 'Science Fiction'),
        Genre(16, 'Animation')
      ]);
  @override
  Future<List<Movie>> discoverByGenre(int? id, String l) => _fallback(
      () => remote.discover(id, l),
      id == null
          ? mockMovies
          : mockMovies.where((m) => m.genreIds.contains(id)).toList());
  @override
  Future<Movie> getDetails(int id, String l) async {
    final fallback = mockMovies.firstWhere((m) => m.id == id,
        orElse: () => mockMovies.first);
    return _fallback(() => remote.details(id, l), fallback);
  }
}
