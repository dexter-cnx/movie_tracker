import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:popcorn_movie_tracker/features/watchlist/data/watchlist_local_data_source.dart';
import 'package:popcorn_movie_tracker/features/watchlist/domain/watchlist_item.dart';
import 'package:popcorn_movie_tracker/features/watchlist/presentation/watchlist_controller.dart';

class MockWatchlistLocalDataSource extends Mock
    implements WatchlistLocalDataSource {}

void main() {
  late MockWatchlistLocalDataSource source;
  late ProviderContainer container;

  final item = WatchlistItem(
    id: '1',
    movieId: 1,
    title: 'Movie',
    status: WatchStatus.favorite,
    addedAt: DateTime.utc(2026, 7, 1),
  );

  setUp(() {
    source = MockWatchlistLocalDataSource();
    when(() => source.getAll()).thenReturn([]);
    container = ProviderContainer(
      overrides: [watchlistDataSourceProvider.overrideWithValue(source)],
    );
    addTearDown(container.dispose);
  });

  test('initial state comes from local data source', () {
    expect(container.read(watchlistControllerProvider), isEmpty);
    verify(() => source.getAll()).called(1);
  });

  test('save persists and refreshes state', () async {
    when(() => source.save(item)).thenAnswer((_) async {});
    container.read(watchlistControllerProvider);
    when(() => source.getAll()).thenReturn([item]);

    await container.read(watchlistControllerProvider.notifier).save(item);

    expect(container.read(watchlistControllerProvider), [item]);
    verify(() => source.save(item)).called(1);
  });

  test('delete removes and refreshes state', () async {
    when(() => source.getAll()).thenReturn([item]);
    container.read(watchlistControllerProvider);
    when(() => source.delete(item.id)).thenAnswer((_) async {});
    when(() => source.getAll()).thenReturn([]);

    await container.read(watchlistControllerProvider.notifier).delete(item.id);

    expect(container.read(watchlistControllerProvider), isEmpty);
    verify(() => source.delete(item.id)).called(1);
  });
}
