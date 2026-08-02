import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:popcorn_movie_tracker/core/errors/app_failure.dart';
import 'package:popcorn_movie_tracker/features/movies/data/mock_movies.dart';
import 'package:popcorn_movie_tracker/features/movies/data/movie_cache_local_data_source.dart';
import 'package:popcorn_movie_tracker/features/movies/data/movie_repository_impl.dart';
import 'package:popcorn_movie_tracker/features/movies/data/tmdb_remote_data_source.dart';
import 'package:popcorn_movie_tracker/features/movies/domain/entities/movie_load_result.dart';

class MockRemoteDataSource extends Mock implements TmdbRemoteDataSource {}

class MockMovieCache extends Mock implements MovieCacheLocalDataSource {}

void main() {
  late MockRemoteDataSource remote;
  late MockMovieCache cache;
  late DateTime now;
  late MovieRepositoryImpl repository;

  setUp(() {
    remote = MockRemoteDataSource();
    cache = MockMovieCache();
    now = DateTime.utc(2026, 8, 2, 3);
    repository = MovieRepositoryImpl(
      remote,
      cache: cache,
      cacheTtl: const Duration(minutes: 30),
      now: () => now,
    );
  });

  test('returns fresh cache without calling the network', () async {
    final cached = CachedMovieList(
      movies: mockMovies.take(2).toList(),
      cachedAt: now.subtract(const Duration(minutes: 10)),
    );
    when(() => cache.read('trending:en-US')).thenReturn(cached);

    final result = await repository.getTrendingFeed('en-US');

    expect(result.source, MovieDataSource.freshCache);
    expect(result.movies, cached.movies);
    verifyNever(() => remote.trending(any()));
  });

  test('refreshes an expired cache and persists network data', () async {
    final stale = CachedMovieList(
      movies: mockMovies.take(1).toList(),
      cachedAt: now.subtract(const Duration(hours: 2)),
    );
    final networkMovies = mockMovies.skip(1).take(2).toList();
    when(() => cache.read('trending:en-US')).thenReturn(stale);
    when(() => remote.trending('en-US')).thenAnswer((_) async => networkMovies);
    when(() => cache.write('trending:en-US', networkMovies, now))
        .thenAnswer((_) async {});

    final result = await repository.getTrendingFeed('en-US');

    expect(result.source, MovieDataSource.network);
    expect(result.movies, networkMovies);
    verify(() => cache.write('trending:en-US', networkMovies, now)).called(1);
  });

  test('returns stale cache with typed failure when network fails', () async {
    final stale = CachedMovieList(
      movies: mockMovies.take(2).toList(),
      cachedAt: now.subtract(const Duration(hours: 2)),
    );
    when(() => cache.read('trending:en-US')).thenReturn(stale);
    when(() => remote.trending('en-US')).thenThrow(Exception('offline'));

    final result = await repository.getTrendingFeed('en-US');

    expect(result.source, MovieDataSource.staleCache);
    expect(result.movies, stale.movies);
    expect(result.failure, isA<UnknownFailure>());
  });

  test('returns mock data when both network and cache are unavailable',
      () async {
    when(() => cache.read('trending:en-US')).thenReturn(null);
    when(() => remote.trending('en-US')).thenThrow(Exception('offline'));

    final result = await repository.getTrendingFeed('en-US');

    expect(result.source, MovieDataSource.mock);
    expect(result.movies, mockMovies);
    expect(result.failure, isNotNull);
  });

  test('force refresh bypasses a fresh cache', () async {
    final cached = CachedMovieList(
      movies: mockMovies.take(1).toList(),
      cachedAt: now.subtract(const Duration(minutes: 1)),
    );
    final networkMovies = mockMovies.skip(3).take(2).toList();
    when(() => cache.read('trending:en-US')).thenReturn(cached);
    when(() => remote.trending('en-US')).thenAnswer((_) async => networkMovies);
    when(() => cache.write('trending:en-US', networkMovies, now))
        .thenAnswer((_) async {});

    final result = await repository.getTrendingFeed(
      'en-US',
      forceRefresh: true,
    );

    expect(result.source, MovieDataSource.network);
    verify(() => remote.trending('en-US')).called(1);
  });
}
