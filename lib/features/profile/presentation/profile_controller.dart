import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:popcorn_movie_tracker/features/profile/data/user_preferences_local_data_source.dart';
import 'package:popcorn_movie_tracker/features/profile/domain/user_preferences.dart';

final userPreferencesDataSourceProvider = Provider(
  (ref) => UserPreferencesLocalDataSource(
    Hive.box<Map>(UserPreferencesLocalDataSource.boxName),
  ),
);

final profileControllerProvider =
    NotifierProvider<ProfileController, UserPreferences>(
  ProfileController.new,
);

class ProfileController extends Notifier<UserPreferences> {
  UserPreferencesLocalDataSource get _source =>
      ref.read(userPreferencesDataSourceProvider);

  @override
  UserPreferences build() => _source.load();

  Future<void> updateProfile({
    required String displayName,
    required String email,
    required String favoriteGenre,
  }) async {
    final next = state.copyWith(
      displayName: displayName.trim().isEmpty ? 'Alex' : displayName.trim(),
      email: email.trim(),
      favoriteGenre: favoriteGenre.trim(),
    );
    await _save(next);
  }

  Future<void> setLanguage(String languageCode) async {
    await _save(state.copyWith(languageCode: languageCode));
  }

  Future<void> setNotificationsEnabled(bool value) async {
    await _save(state.copyWith(notificationsEnabled: value));
  }

  Future<void> setAutoplayTrailers(bool value) async {
    await _save(state.copyWith(autoplayTrailers: value));
  }

  Future<void> _save(UserPreferences next) async {
    await _source.save(next);
    state = next;
  }
}
