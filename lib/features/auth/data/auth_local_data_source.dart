import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:popcorn_movie_tracker/features/auth/domain/auth_session.dart';

abstract interface class AuthLocalDataSource {
  Future<AuthSession?> read();
  Future<void> write(AuthSession session);
  Future<void> clear();
}

class SecureAuthLocalDataSource implements AuthLocalDataSource {
  const SecureAuthLocalDataSource(this.storage);

  static const _userIdKey = 'auth.userId';
  static const _accessTokenKey = 'auth.accessToken';
  static const _refreshTokenKey = 'auth.refreshToken';
  static const _expiresAtKey = 'auth.expiresAt';

  final FlutterSecureStorage storage;

  @override
  Future<AuthSession?> read() async {
    final values = await storage.readAll();
    final userId = values[_userIdKey];
    final accessToken = values[_accessTokenKey];
    final refreshToken = values[_refreshTokenKey];
    final expiresAt = DateTime.tryParse(values[_expiresAtKey] ?? '');

    if (userId == null ||
        accessToken == null ||
        refreshToken == null ||
        expiresAt == null) {
      return null;
    }

    return AuthSession(
      userId: userId,
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
    );
  }

  @override
  Future<void> write(AuthSession session) async {
    await Future.wait([
      storage.write(key: _userIdKey, value: session.userId),
      storage.write(key: _accessTokenKey, value: session.accessToken),
      storage.write(key: _refreshTokenKey, value: session.refreshToken),
      storage.write(
          key: _expiresAtKey, value: session.expiresAt.toIso8601String()),
    ]);
  }

  @override
  Future<void> clear() async {
    await Future.wait([
      storage.delete(key: _userIdKey),
      storage.delete(key: _accessTokenKey),
      storage.delete(key: _refreshTokenKey),
      storage.delete(key: _expiresAtKey),
    ]);
  }
}
