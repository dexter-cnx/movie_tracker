import 'package:easy_localization/easy_localization.dart';
import 'package:easy_localization_loader/easy_localization_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:popcorn_movie_tracker/features/profile/data/user_preferences_local_data_source.dart';
import 'package:popcorn_movie_tracker/features/profile/domain/user_preferences.dart';
import 'package:popcorn_movie_tracker/features/profile/presentation/profile_controller.dart';
import 'package:popcorn_movie_tracker/features/profile/presentation/profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockPreferencesDataSource extends Mock
    implements UserPreferencesLocalDataSource {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(const {});
    registerFallbackValue(const UserPreferences());
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('shows profile details and settings', (tester) async {
    final source = MockPreferencesDataSource();
    when(() => source.load()).thenReturn(
      const UserPreferences(
        displayName: 'Dexter',
        email: 'dexter@example.com',
        favoriteGenre: 'Science Fiction',
      ),
    );
    when(() => source.save(any())).thenAnswer((_) async {});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userPreferencesDataSourceProvider.overrideWithValue(source),
        ],
        child: EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('th')],
          path: 'assets/langs/langs.csv',
          fallbackLocale: const Locale('en'),
          startLocale: const Locale('en'),
          assetLoader: CsvAssetLoader(),
          child: const MaterialApp(home: Scaffold(body: ProfilePage())),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Dexter'), findsOneWidget);
    expect(find.text('dexter@example.com'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Autoplay trailers'), findsOneWidget);
  });
}
