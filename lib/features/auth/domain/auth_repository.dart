import 'package:popcorn_movie_tracker/features/auth/domain/auth_session.dart';

abstract interface class AuthRepository {
  Future<AuthSession?> restore();
  Future<AuthSession> login({required String email, required String password});
  Future<AuthSession> validSession();
  Future<void> logout();
}
