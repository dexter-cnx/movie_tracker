import 'package:easy_localization/easy_localization.dart';
import 'package:easy_localization_loader/easy_localization_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:popcorn_movie_tracker/features/profile/data/user_preferences_local_data_source.dart';
import 'package:popcorn_movie_tracker/features/profile/domain/user_preferences.dart';
import 'package:popcorn_movie_tracker/features/profile/presentation/profile_controller.dart';
import 'package:popcorn_movie_tracker/features/profile/presentation/profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockPreferencesDataSource extends Mock
    implements UserPreferencesLocalDataSource {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(const {});
    registerFallbackValue(const UserPreferences());
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('edits profile and changes language with persisted state',
      (tester) async {
    var stored = const UserPreferences(displayName: 'Alex');
    final source = MockPreferencesDataSource();
    when(() => source.load()).thenAnswer((_) => stored);
    when(() => source.save(any())).thenAnswer((invocation) async {
      stored = invocation.positionalArguments.single as UserPreferences;
    });

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

    await tester.tap(find.byTooltip('Edit profile'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Dexter');
    await tester.enterText(fields.at(1), 'dexter@example.com');
    await tester.enterText(fields.at(2), 'Science Fiction');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Dexter'), findsOneWidget);
    expect(find.text('dexter@example.com'), findsOneWidget);
    expect(stored.displayName, 'Dexter');

    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thai'));
    await tester.pumpAndSettle();

    expect(stored.languageCode, 'th');
    expect(find.text('โปรไฟล์'), findsOneWidget);
  });
}
