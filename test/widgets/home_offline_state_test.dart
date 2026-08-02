import 'package:easy_localization/easy_localization.dart';
import 'package:easy_localization_loader/easy_localization_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:popcorn_movie_tracker/core/errors/app_failure.dart';
import 'package:popcorn_movie_tracker/features/home/presentation/home_page.dart';
import 'package:popcorn_movie_tracker/features/movies/data/mock_movies.dart';
import 'package:popcorn_movie_tracker/features/movies/domain/entities/movie_load_result.dart';
import 'package:popcorn_movie_tracker/features/movies/presentation/movie_providers.dart';
import 'package:popcorn_movie_tracker/features/profile/data/user_preferences_local_data_source.dart';
import 'package:popcorn_movie_tracker/features/profile/domain/user_preferences.dart';
import 'package:popcorn_movie_tracker/features/profile/presentation/profile_controller.dart';
import 'package:popcorn_movie_tracker/features/watchlist/data/watchlist_local_data_source.dart';
import 'package:popcorn_movie_tracker/features/watchlist/presentation/watchlist_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockProfileSource extends Mock implements UserPreferencesLocalDataSource {}

class MockWatchlistSource extends Mock implements WatchlistLocalDataSource {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(const {});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('shows stale-cache notice and keeps movie content visible',
      (tester) async {
    final profileSource = MockProfileSource();
    final watchlistSource = MockWatchlistSource();
    when(() => profileSource.load()).thenReturn(
      const UserPreferences(displayName: 'Dexter'),
    );
    when(() => watchlistSource.getAll()).thenReturn(const []);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userPreferencesDataSourceProvider.overrideWithValue(profileSource),
          watchlistDataSourceProvider.overrideWithValue(watchlistSource),
          trendingFeedProvider.overrideWith(
            (ref, language) async => MovieLoadResult(
              movies: mockMovies,
              source: MovieDataSource.staleCache,
              failure: const NetworkFailure(),
            ),
          ),
        ],
        child: EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('th')],
          path: 'assets/langs/langs.csv',
          fallbackLocale: const Locale('en'),
          startLocale: const Locale('en'),
          assetLoader: CsvAssetLoader(),
          child: const MaterialApp(home: Scaffold(body: HomePage())),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Showing previously cached movies'), findsOneWidget);
    expect(find.text(mockMovies.first.title), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
