import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:popcorn_movie_tracker/features/watchlist/data/watchlist_local_data_source.dart';
import 'package:popcorn_movie_tracker/features/watchlist/domain/watchlist_item.dart';
import 'package:popcorn_movie_tracker/features/watchlist/presentation/watchlist_controller.dart';
import 'package:popcorn_movie_tracker/features/watchlist/presentation/watchlist_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_localization.dart';

class MockWatchlistSource extends Mock implements WatchlistLocalDataSource {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(const {});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('changes grid columns from screen ratio rather than width alone',
      (tester) async {
    final source = MockWatchlistSource();
    when(() => source.getAll()).thenReturn([
      WatchlistItem(
        id: '1',
        movieId: 1,
        title: 'Ratio Movie',
        status: WatchStatus.wantToWatch,
        addedAt: DateTime.utc(2026, 8, 2),
      ),
    ]);

    Future<void> pumpAt(Size size) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            watchlistDataSourceProvider.overrideWithValue(source),
          ],
          child: testLocalizedApp(home: const WatchlistPage()),
        ),
      );
      await tester.pumpAndSettle();
    }

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await pumpAt(const Size(390, 844));
    var movieGrid = tester.widget<GridView>(
      find.byKey(WatchlistPage.movieGridKey),
    );
    var delegate =
        movieGrid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 2);

    await pumpAt(const Size(1600, 900));
    movieGrid = tester.widget<GridView>(
      find.byKey(WatchlistPage.movieGridKey),
    );
    delegate =
        movieGrid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 5);
  });
}
