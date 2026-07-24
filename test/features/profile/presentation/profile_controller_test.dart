import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:popcorn_movie_tracker/features/profile/data/user_preferences_local_data_source.dart';
import 'package:popcorn_movie_tracker/features/profile/domain/user_preferences.dart';
import 'package:popcorn_movie_tracker/features/profile/presentation/profile_controller.dart';

class MockPreferencesDataSource extends Mock
    implements UserPreferencesLocalDataSource {}

void main() {
  late MockPreferencesDataSource source;
  late ProviderContainer container;

  setUp(() {
    source = MockPreferencesDataSource();
    when(() => source.load()).thenReturn(const UserPreferences());
    when(() => source.save(any())).thenAnswer((_) async {});

    container = ProviderContainer(
      overrides: [
        userPreferencesDataSourceProvider.overrideWithValue(source),
      ],
    );
    addTearDown(container.dispose);
  });

  test('loads initial preferences', () {
    final state = container.read(profileControllerProvider);

    expect(state.displayName, 'Alex');
    verify(() => source.load()).called(1);
  });

  test('updates and persists profile fields', () async {
    final controller = container.read(profileControllerProvider.notifier);

    await controller.updateProfile(
      displayName: ' Dexter ',
      email: ' dexter@example.com ',
      favoriteGenre: ' Sci-Fi ',
    );

    final state = container.read(profileControllerProvider);
    expect(state.displayName, 'Dexter');
    expect(state.email, 'dexter@example.com');
    expect(state.favoriteGenre, 'Sci-Fi');
    verify(() => source.save(state)).called(1);
  });

  test('updates settings independently', () async {
    final controller = container.read(profileControllerProvider.notifier);

    await controller.setLanguage('th');
    await controller.setNotificationsEnabled(false);
    await controller.setAutoplayTrailers(true);

    final state = container.read(profileControllerProvider);
    expect(state.languageCode, 'th');
    expect(state.notificationsEnabled, isFalse);
    expect(state.autoplayTrailers, isTrue);
    verify(() => source.save(any())).called(3);
  });
}
