import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:popcorn_movie_tracker/features/auth/data/auth_local_data_source.dart';
import 'package:popcorn_movie_tracker/features/auth/data/auth_remote_data_source.dart';
import 'package:popcorn_movie_tracker/features/auth/data/auth_repository_impl.dart';
import 'package:popcorn_movie_tracker/features/auth/domain/auth_session.dart';

class MockAuthRemote extends Mock implements AuthRemoteDataSource {}

class MockAuthLocal extends Mock implements AuthLocalDataSource {}

void main() {
  late MockAuthRemote remote;
  late MockAuthLocal local;
  final now = DateTime(2026, 8, 2, 10);

  setUpAll(() {
    registerFallbackValue(
      AuthSession(
        userId: 'fallback',
        accessToken: 'access',
        refreshToken: 'refresh',
        expiresAt: DateTime(2026),
      ),
    );
  });

  setUp(() {
    remote = MockAuthRemote();
    local = MockAuthLocal();
    when(() => local.write(any())).thenAnswer((_) async {});
    when(() => local.clear()).thenAnswer((_) async {});
  });

  test('returns a stored session while it is valid', () async {
    final session = AuthSession(
      userId: 'user',
      accessToken: 'access',
      refreshToken: 'refresh',
      expiresAt: now.add(const Duration(minutes: 10)),
    );
    when(() => local.read()).thenAnswer((_) async => session);

    final repository =
        AuthRepositoryImpl(remote: remote, local: local, now: () => now);

    expect(await repository.restore(), same(session));
    verifyNever(() => remote.refresh(any()));
  });

  test('deduplicates concurrent refresh calls', () async {
    final expired = AuthSession(
      userId: 'user',
      accessToken: 'old',
      refreshToken: 'demo-refresh-1',
      expiresAt: now.subtract(const Duration(seconds: 1)),
    );
    final refreshed = AuthSession(
      userId: 'ignored',
      accessToken: 'new',
      refreshToken: 'demo-refresh-1',
      expiresAt: now.add(const Duration(minutes: 15)),
    );
    when(() => local.read()).thenAnswer((_) async => expired);
    when(() => remote.refresh('demo-refresh-1'))
        .thenAnswer((_) async => refreshed);

    final repository =
        AuthRepositoryImpl(remote: remote, local: local, now: () => now);
    await repository.restore();

    final results = await Future.wait([
      repository.validSession(),
      repository.validSession(),
      repository.validSession(),
    ]);

    expect(results.every((session) => session.accessToken == 'new'), isTrue);
    verify(() => remote.refresh('demo-refresh-1')).called(1);
  });

  test('clears local session when refresh token is rejected', () async {
    final expired = AuthSession(
      userId: 'user',
      accessToken: 'old',
      refreshToken: 'invalid',
      expiresAt: now.subtract(const Duration(seconds: 1)),
    );
    when(() => local.read()).thenAnswer((_) async => expired);
    when(() => remote.refresh('invalid'))
        .thenThrow(const RefreshTokenExpiredException());

    final repository =
        AuthRepositoryImpl(remote: remote, local: local, now: () => now);

    expect(await repository.restore(), isNull);
    verify(() => local.clear()).called(1);
  });
}
