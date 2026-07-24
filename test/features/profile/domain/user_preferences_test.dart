import 'package:flutter_test/flutter_test.dart';
import 'package:popcorn_movie_tracker/features/profile/domain/user_preferences.dart';

void main() {
  test('uses safe defaults', () {
    const preferences = UserPreferences();

    expect(preferences.displayName, 'Alex');
    expect(preferences.languageCode, 'en');
    expect(preferences.notificationsEnabled, isTrue);
    expect(preferences.autoplayTrailers, isFalse);
  });

  test('round trips through map', () {
    const original = UserPreferences(
      displayName: 'Dexter',
      email: 'dexter@example.com',
      favoriteGenre: 'Science Fiction',
      languageCode: 'th',
      notificationsEnabled: false,
      autoplayTrailers: true,
    );

    final restored = UserPreferences.fromMap(original.toMap());

    expect(restored.displayName, original.displayName);
    expect(restored.email, original.email);
    expect(restored.favoriteGenre, original.favoriteGenre);
    expect(restored.languageCode, 'th');
    expect(restored.notificationsEnabled, isFalse);
    expect(restored.autoplayTrailers, isTrue);
  });

  test('normalizes invalid stored values', () {
    final restored = UserPreferences.fromMap({
      'displayName': '   ',
      'languageCode': 'jp',
    });

    expect(restored.displayName, 'Alex');
    expect(restored.languageCode, 'en');
    expect(restored.notificationsEnabled, isTrue);
  });
}
