import 'package:easy_localization/easy_localization.dart';
import 'package:easy_localization_loader/easy_localization_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:popcorn_movie_tracker/features/movie_detail/presentation/movie_detail_page.dart';
import 'package:popcorn_movie_tracker/features/movies/domain/entities/movie.dart';
import 'package:popcorn_movie_tracker/features/movies/domain/repositories/movie_repository.dart';
import 'package:popcorn_movie_tracker/features/movies/presentation/movie_providers.dart';
import 'package:popcorn_movie_tracker/features/watchlist/data/watchlist_local_data_source.dart';
import 'package:popcorn_movie_tracker/features/watchlist/presentation/watchlist_controller.dart';
import 'package:popcorn_movie_tracker/features/watchlist/presentation/watchlist_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockMovieRepository extends Mock implements MovieRepository {}

class MockBox extends Mock implements Box<Map> {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(const {});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('adds a movie from detail and shows it in watchlist',
      (tester) async {
    final records = <dynamic, Map>{};
    final box = MockBox();
    when(() => box.values).thenAnswer((_) => records.values);
    when(() => box.put(any(), any())).thenAnswer((invocation) async {
      records[invocation.positionalArguments[0]] =
          invocation.positionalArguments[1] as Map;
    });
    when(() => box.delete(any())).thenAnswer((invocation) async {
      records.remove(invocation.positionalArguments[0]);
    });

    const movie = Movie(
      id: 42,
      title: 'Integration Movie',
      overview: 'A deterministic movie used by the integration test.',
      releaseDate: '2026-08-02',
      voteAverage: 8.5,
      genreIds: [18],
      runtime: 120,
      genres: ['Drama'],
    );

    final repository = MockMovieRepository();
    when(() => repository.getDetails(42, any())).thenAnswer((_) async => movie);

    final router = GoRouter(
      initialLocation: '/movie/42',
      routes: [
        GoRoute(
          path: '/movie/:id',
          builder: (_, __) => const MovieDetailPage(movieId: 42),
        ),
        GoRoute(
          path: '/watchlist',
          builder: (_, __) => const Scaffold(body: WatchlistPage()),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          movieRepositoryProvider.overrideWithValue(repository),
          watchlistDataSourceProvider.overrideWithValue(
            WatchlistLocalDataSource(box),
          ),
        ],
        child: EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('th')],
          path: 'assets/langs/langs.csv',
          fallbackLocale: const Locale('en'),
          startLocale: const Locale('en'),
          assetLoader: CsvAssetLoader(),
          child: MaterialApp.router(routerConfig: router),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Add to Watchlist'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Add to Watchlist'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(records, hasLength(1));

    router.go('/watchlist');
    await tester.pumpAndSettle();

    expect(find.text('Integration Movie'), findsOneWidget);
    expect(find.text('Want to Watch'), findsOneWidget);
  });
}
