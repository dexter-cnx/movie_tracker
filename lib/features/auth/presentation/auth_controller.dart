import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:popcorn_movie_tracker/features/auth/data/auth_local_data_source.dart';
import 'package:popcorn_movie_tracker/features/auth/data/auth_remote_data_source.dart';
import 'package:popcorn_movie_tracker/features/auth/data/auth_repository_impl.dart';
import 'package:popcorn_movie_tracker/features/auth/domain/auth_repository.dart';
import 'package:popcorn_movie_tracker/features/auth/domain/auth_session.dart';

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>(
  (_) => const SecureAuthLocalDataSource(FlutterSecureStorage()),
);

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (_) => DemoAuthRemoteDataSource(),
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remote: ref.watch(authRemoteDataSourceProvider),
    local: ref.watch(authLocalDataSourceProvider),
  );
});

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthSession?>(AuthController.new);

class AuthController extends AsyncNotifier<AuthSession?> {
  @override
  Future<AuthSession?> build() {
    return ref.watch(authRepositoryProvider).restore();
  }

  Future<bool> login({required String email, required String password}) async {
    state = const AsyncLoading();
    try {
      final session = await ref.read(authRepositoryProvider).login(
            email: email,
            password: password,
          );
      state = AsyncData(session);
      return true;
    } on Object catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }

  Future<AuthSession?> ensureValidSession() async {
    try {
      final session = await ref.read(authRepositoryProvider).validSession();
      state = AsyncData(session);
      return session;
    } on Object catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }
}
