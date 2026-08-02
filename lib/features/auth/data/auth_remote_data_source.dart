import 'package:popcorn_movie_tracker/features/auth/domain/auth_session.dart';

abstract interface class AuthRemoteDataSource {
  Future<AuthSession> login({required String email, required String password});
  Future<AuthSession> refresh(String refreshToken);
}

class DemoAuthRemoteDataSource implements AuthRemoteDataSource {
  DemoAuthRemoteDataSource({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  @override
  Future<AuthSession> login({required String email, required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!email.contains('@') || password.length < 6) {
      throw const AuthCredentialsException();
    }
    final stamp = _now().millisecondsSinceEpoch;
    return AuthSession(
      userId: email.trim().toLowerCase(),
      accessToken: 'demo-access-$stamp',
      refreshToken: 'demo-refresh-$stamp',
      expiresAt: _now().add(const Duration(minutes: 15)),
    );
  }

  @override
  Future<AuthSession> refresh(String refreshToken) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (!refreshToken.startsWith('demo-refresh-')) {
      throw const RefreshTokenExpiredException();
    }
    final stamp = _now().millisecondsSinceEpoch;
    return AuthSession(
      userId: 'restored-user',
      accessToken: 'demo-access-$stamp',
      refreshToken: refreshToken,
      expiresAt: _now().add(const Duration(minutes: 15)),
    );
  }
}

class AuthCredentialsException implements Exception {
  const AuthCredentialsException();
}

class RefreshTokenExpiredException implements Exception {
  const RefreshTokenExpiredException();
}
