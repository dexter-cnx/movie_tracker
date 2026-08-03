import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:popcorn_movie_tracker/core/app_info/app_info_provider.dart';
import 'package:popcorn_movie_tracker/features/auth/data/auth_local_data_source.dart';
import 'package:popcorn_movie_tracker/features/auth/domain/auth_session.dart';
import 'package:popcorn_movie_tracker/features/auth/presentation/auth_controller.dart';
import 'package:popcorn_movie_tracker/features/profile/data/user_preferences_local_data_source.dart';
import 'package:popcorn_movie_tracker/features/profile/domain/user_preferences.dart';
import 'package:popcorn_movie_tracker/features/profile/presentation/profile_controller.dart';
import 'package:popcorn_movie_tracker/features/profile/presentation/profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_localization.dart';

class MockPreferencesDataSource extends Mock
    implements UserPreferencesLocalDataSource {}

class FakeAuthLocalDataSource implements AuthLocalDataSource {
  @override
  Future<void> clear() async {}

  @override
  Future<AuthSession?> read() async => null;

  @override
  Future<void> write(AuthSession session) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(const {});
    registerFallbackValue(const UserPreferences());
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('shows profile account details and settings', (tester) async {
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
          authLocalDataSourceProvider.overrideWithValue(
            FakeAuthLocalDataSource(),
          ),
          appInfoProvider.overrideWith(
            (_) async => const AppInfo(version: '1.1.0', buildNumber: '2'),
          ),
        ],
        child: EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('th')],
          path: 'unused-in-widget-tests',
          fallbackLocale: const Locale('en'),
          startLocale: const Locale('en'),
          assetLoader: const TestLocalizationLoader(),
          child: const MaterialApp(home: Scaffold(body: ProfilePage())),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Dexter'), findsOneWidget);
    expect(find.text('dexter@example.com'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Autoplay trailers'), findsOneWidget);
    expect(find.text('Version 1.1.0+2'), findsOneWidget);
  });
}
