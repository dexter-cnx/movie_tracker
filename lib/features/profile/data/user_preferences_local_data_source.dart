import 'package:hive/hive.dart';
import 'package:popcorn_movie_tracker/features/profile/domain/user_preferences.dart';

class UserPreferencesLocalDataSource {
  UserPreferencesLocalDataSource(this.box);

  static const boxName = 'user_preferences';
  static const _recordKey = 'current';

  final Box<Map> box;

  UserPreferences load() {
    final value = box.get(_recordKey);
    return value == null
        ? const UserPreferences()
        : UserPreferences.fromMap(value);
  }

  Future<void> save(UserPreferences preferences) {
    return box.put(_recordKey, preferences.toMap());
  }
}
