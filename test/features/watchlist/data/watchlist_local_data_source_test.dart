import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:popcorn_movie_tracker/features/watchlist/data/watchlist_local_data_source.dart';
import 'package:popcorn_movie_tracker/features/watchlist/domain/watchlist_item.dart';

class MockBox extends Mock implements Box<Map> {}

void main() {
  late MockBox box;
  late WatchlistLocalDataSource source;

  setUp(() {
    box = MockBox();
    source = WatchlistLocalDataSource(box);
  });

  WatchlistItem item(String id, DateTime addedAt) => WatchlistItem(
        id: id,
        movieId: id.hashCode,
        title: id,
        status: WatchStatus.wantToWatch,
        addedAt: addedAt,
      );

  test('getAll maps values and sorts newest first', () {
    final older = item('older', DateTime.utc(2026, 1, 1));
    final newer = item('newer', DateTime.utc(2026, 2, 1));
    when(() => box.values).thenReturn([older.toMap(), newer.toMap()]);

    final result = source.getAll();

    expect(result.map((e) => e.id), ['newer', 'older']);
  });

  test('save persists item map under item id', () async {
    final value = item('movie-1', DateTime.utc(2026, 1, 1));
    when(() => box.put(any(), any())).thenAnswer((_) async {});

    await source.save(value);

    final captured = verify(() => box.put('movie-1', captureAny())).captured.single as Map;
    expect(captured['id'], 'movie-1');
    expect(captured['title'], 'movie-1');
  });

  test('delete removes item by id', () async {
    when(() => box.delete(any())).thenAnswer((_) async {});

    await source.delete('movie-1');

    verify(() => box.delete('movie-1')).called(1);
  });
}
