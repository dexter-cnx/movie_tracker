import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:popcorn_movie_tracker/features/movies/data/mock_movies.dart';
import 'package:popcorn_movie_tracker/features/movies/data/movie_repository_impl.dart';
import 'package:popcorn_movie_tracker/features/movies/data/tmdb_remote_data_source.dart';
import 'package:popcorn_movie_tracker/features/movies/domain/entities/movie.dart';
import 'package:popcorn_movie_tracker/features/movies/domain/repositories/movie_repository.dart';

class MockTmdbRemoteDataSource extends Mock implements TmdbRemoteDataSource {}

void main() {
  late MockTmdbRemoteDataSource remote;
  late MovieRepositoryImpl repository;

  setUp(() {
    remote = MockTmdbRemoteDataSource();
    repository = MovieRepositoryImpl(remote);
  });

  group('MovieRepositoryImpl', () {
    test('returns remote data when request succeeds', () async {
      final movies = <Movie>[
        const Movie(
          id: 100,
          title: 'Remote Movie',
          overview: '',
          releaseDate: '2026-01-01',
          voteAverage: 8,
          genreIds: [28],
        ),
      ];
      when(() => remote.trending('en-US')).thenAnswer((_) async => movies);

      final result = await repository.getTrending('en-US');

      expect(result, same(movies));
    });

    test('falls back to mock movies when popular request fails', () async {
      when(() => remote.popular('en-US')).thenThrow(Exception('network'));

      final result = await repository.getPopular('en-US');

      expect(result, mockMovies);
    });

    test('top rated fallback is sorted by descending vote average', () async {
      when(() => remote.topRated('en-US')).thenThrow(Exception('network'));

      final result = await repository.getTopRated('en-US');

      for (var i = 1; i < result.length; i++) {
        expect(result[i - 1].voteAverage >= result[i].voteAverage, isTrue);
      }
    });

    test('search fallback filters mock movies case-insensitively', () async {
      when(() => remote.search('dune', 'en-US')).thenThrow(Exception('network'));

      final result = await repository.search('dune', 'en-US');

      expect(result, isNotEmpty);
      expect(result.every((movie) => movie.title.toLowerCase().contains('dune')), isTrue);
    });

    test('genre fallback returns built-in genres', () async {
      when(() => remote.genres('th-TH')).thenThrow(Exception('network'));

      final result = await repository.getGenres('th-TH');

      expect(result.map((genre) => genre.id), containsAll(<int>[28, 35, 18, 878, 16]));
    });

    test('discover fallback filters by genre id', () async {
      when(() => remote.discover(878, 'en-US')).thenThrow(Exception('network'));

      final result = await repository.discoverByGenre(878, 'en-US');

      expect(result.every((movie) => movie.genreIds.contains(878)), isTrue);
    });

    test('details fallback returns matching mock movie when available', () async {
      final target = mockMovies.first;
      when(() => remote.details(target.id, 'en-US')).thenThrow(Exception('network'));

      final result = await repository.getDetails(target.id, 'en-US');

      expect(result.id, target.id);
      expect(result.title, target.title);
    });

    test('details fallback returns first mock movie for unknown id', () async {
      when(() => remote.details(999999, 'en-US')).thenThrow(Exception('network'));

      final result = await repository.getDetails(999999, 'en-US');

      expect(result.id, mockMovies.first.id);
    });
  });
}
