import 'dart:async';

import 'package:popcorn_movie_tracker/features/auth/data/auth_local_data_source.dart';
import 'package:popcorn_movie_tracker/features/auth/data/auth_remote_data_source.dart';
import 'package:popcorn_movie_tracker/features/auth/domain/auth_repository.dart';
import 'package:popcorn_movie_tracker/features/auth/domain/auth_session.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required this.remote,
    required this.local,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final AuthRemoteDataSource remote;
  final AuthLocalDataSource local;
  final DateTime Function() _now;

  AuthSession? _session;
  Future<AuthSession>? _refreshInFlight;

  @override
  Future<AuthSession?> restore() async {
    _session = await local.read();
    if (_session == null) return null;

    try {
      return await validSession();
    } on RefreshTokenExpiredException {
      await logout();
      return null;
    }
  }

  @override
  Future<AuthSession> login(
      {required String email, required String password}) async {
    final session = await remote.login(email: email, password: password);
    _session = session;
    await local.write(session);
    return session;
  }

  @override
  Future<AuthSession> validSession() async {
    final current = _session ?? await local.read();
    if (current == null) throw const MissingSessionException();
    _session = current;

    if (!current.isExpired(_now())) return current;

    return _refreshInFlight ??= _refresh(current).whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<AuthSession> _refresh(AuthSession current) async {
    final refreshed = await remote.refresh(current.refreshToken);
    final normalized = AuthSession(
      userId: current.userId,
      accessToken: refreshed.accessToken,
      refreshToken: refreshed.refreshToken,
      expiresAt: refreshed.expiresAt,
    );
    _session = normalized;
    await local.write(normalized);
    return normalized;
  }

  @override
  Future<void> logout() async {
    _session = null;
    await local.clear();
  }
}

class MissingSessionException implements Exception {
  const MissingSessionException();
}
