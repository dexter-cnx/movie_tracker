import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:popcorn_movie_tracker/features/movies/data/mock_movies.dart';
import 'package:popcorn_movie_tracker/features/movies/data/movie_cache_local_data_source.dart';

class MockBox extends Mock implements Box<Map> {}

void main() {
  late MockBox box;
  late MovieCacheLocalDataSource source;

  setUp(() {
    box = MockBox();
    source = MovieCacheLocalDataSource(box);
  });

  test('writes movies with cache timestamp', () async {
    when(() => box.put(any(), any())).thenAnswer((_) async {});
    final cachedAt = DateTime.utc(2026, 8, 2, 1);

    await source.write('trending:en-US', mockMovies.take(2).toList(), cachedAt);

    final captured = verify(
      () => box.put('trending:en-US', captureAny()),
    ).captured.single as Map;
    expect(captured['cachedAt'], cachedAt.toIso8601String());
    expect((captured['items'] as List).length, 2);
  });

  test('reads cached movies and freshness metadata', () {
    final cachedAt = DateTime.utc(2026, 8, 2, 1);
    when(() => box.get('trending:en-US')).thenReturn(<String, dynamic>{
      'cachedAt': cachedAt.toIso8601String(),
      'items': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 10,
          'title': 'Cached movie',
          'overview': 'Stored locally',
          'releaseDate': '2026-08-01',
          'voteAverage': 8.2,
          'genreIds': <int>[18],
          'popularity': 50.0,
          'genres': <String>['Drama'],
          'cast': <Map<String, dynamic>>[],
        },
      ],
    });

    final result = source.read('trending:en-US');

    expect(result, isNotNull);
    expect(result!.movies.single.title, 'Cached movie');
    expect(
      result.isFresh(
        const Duration(minutes: 30),
        cachedAt.add(const Duration(minutes: 29)),
      ),
      isTrue,
    );
    expect(
      result.isFresh(
        const Duration(minutes: 30),
        cachedAt.add(const Duration(minutes: 31)),
      ),
      isFalse,
    );
  });

  test('returns null for malformed cached data', () {
    when(() => box.get(any())).thenReturn(<String, dynamic>{
      'cachedAt': 'invalid',
      'items': <dynamic>[],
    });

    expect(source.read('bad'), isNull);
  });
}
