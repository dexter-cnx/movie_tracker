import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:popcorn_movie_tracker/features/profile/data/user_preferences_local_data_source.dart';
import 'package:popcorn_movie_tracker/features/profile/domain/user_preferences.dart';

class MockBox extends Mock implements Box<Map> {}

void main() {
  late MockBox box;
  late UserPreferencesLocalDataSource source;

  setUp(() {
    box = MockBox();
    source = UserPreferencesLocalDataSource(box);
  });

  test('returns defaults when no record exists', () {
    when(() => box.get(any())).thenReturn(null);

    final result = source.load();

    expect(result.displayName, 'Dexter');
    expect(result.languageCode, 'en');
  });

  test('loads stored preferences', () {
    when(() => box.get(any())).thenReturn({
      'displayName': 'Dexter',
      'languageCode': 'th',
      'notificationsEnabled': false,
    });

    final result = source.load();

    expect(result.displayName, 'Dexter');
    expect(result.languageCode, 'th');
    expect(result.notificationsEnabled, isFalse);
  });

  test('saves one current preferences record', () async {
    const preferences = UserPreferences(displayName: 'Dexter');
    when(() => box.put(any(), any())).thenAnswer((_) async {});

    await source.save(preferences);

    verify(() => box.put('current', preferences.toMap())).called(1);
  });
}
