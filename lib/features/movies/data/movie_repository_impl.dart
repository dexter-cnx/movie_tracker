import 'package:popcorn_movie_tracker/core/errors/app_failure.dart';
import 'package:popcorn_movie_tracker/features/movies/data/mock_movies.dart';
import 'package:popcorn_movie_tracker/features/movies/data/movie_cache_local_data_source.dart';
import 'package:popcorn_movie_tracker/features/movies/data/tmdb_remote_data_source.dart';
import 'package:popcorn_movie_tracker/features/movies/domain/entities/movie.dart';
import 'package:popcorn_movie_tracker/features/movies/domain/entities/movie_load_result.dart';
import 'package:popcorn_movie_tracker/features/movies/domain/repositories/movie_repository.dart';

class MovieRepositoryImpl implements MovieRepository {
  MovieRepositoryImpl(
    this.remote, {
    this.cache,
    this.cacheTtl = const Duration(minutes: 30),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final TmdbRemoteDataSource remote;
  final MovieCacheLocalDataSource? cache;
  final Duration cacheTtl;
  final DateTime Function() _now;

  Future<T> _fallback<T>(Future<T> Function() action, T fallback) async {
    try {
      return await action();
    } catch (_) {
      return fallback;
    }
  }

  @override
  Future<MovieLoadResult> getTrendingFeed(
    String language, {
    bool forceRefresh = false,
  }) async {
    final key = 'trending:$language';
    final cached = cache?.read(key);

    if (!forceRefresh && cached != null && cached.isFresh(cacheTtl, _now())) {
      return MovieLoadResult(
        movies: cached.movies,
        source: MovieDataSource.freshCache,
      );
    }

    try {
      final movies = await remote.trending(language);
      await cache?.write(key, movies, _now());
      return MovieLoadResult(
        movies: movies,
        source: MovieDataSource.network,
      );
    } on Object catch (error) {
      final failure = mapExceptionToFailure(error);
      if (cached != null && cached.movies.isNotEmpty) {
        return MovieLoadResult(
          movies: cached.movies,
          source: MovieDataSource.staleCache,
          failure: failure,
        );
      }
      return MovieLoadResult(
        movies: mockMovies,
        source: MovieDataSource.mock,
        failure: failure,
      );
    }
  }

  @override
  Future<List<Movie>> getPopular(String l) =>
      _fallback(() => remote.popular(l), mockMovies);

  @override
  Future<List<Movie>> getTrending(String l) async =>
      (await getTrendingFeed(l)).movies;

  @override
  Future<List<Movie>> getTopRated(String l) => _fallback(
        () => remote.topRated(l),
        [...mockMovies]..sort(
            (a, b) => b.voteAverage.compareTo(a.voteAverage),
          ),
      );

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
            .toList(),
      );

  @override
  Future<List<Genre>> getGenres(String l) =>
      _fallback(() => remote.genres(l), const [
        Genre(28, 'Action'),
        Genre(35, 'Comedy'),
        Genre(18, 'Drama'),
        Genre(878, 'Science Fiction'),
        Genre(16, 'Animation'),
      ]);

  @override
  Future<List<Movie>> discoverByGenre(int? id, String l) => _fallback(
        () => remote.discover(id, l),
        id == null
            ? mockMovies
            : mockMovies.where((m) => m.genreIds.contains(id)).toList(),
      );

  @override
  Future<Movie> getDetails(int id, String l) async {
    final fallback = mockMovies.firstWhere(
      (m) => m.id == id,
      orElse: () => mockMovies.first,
    );
    return _fallback(() => remote.details(id, l), fallback);
  }
}
