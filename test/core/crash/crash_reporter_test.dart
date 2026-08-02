import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:popcorn_movie_tracker/core/crash/crash_reporter.dart';
import 'package:popcorn_movie_tracker/core/logging/app_logger.dart';

class MockAppLogger extends Mock implements AppLogger {}

void main() {
  late MockAppLogger logger;
  late LoggingCrashReporter reporter;

  setUp(() {
    logger = MockAppLogger();
    reporter = LoggingCrashReporter(logger);
  });

  test('initializes the logging provider without external credentials', () async {
    when(() => logger.info(any(), context: any(named: 'context')))
        .thenReturn(null);

    await reporter.initialize();

    verify(
      () => logger.info(
        'Crash reporting initialized',
        context: {
          'provider': 'logging',
          'futureAdapters': 'firebase_crashlytics,sentry',
        },
      ),
    ).called(1);
  });

  test('records fatal error and preserves custom context', () async {
    final error = StateError('boom');
    final stackTrace = StackTrace.current;
    when(
      () => logger.error(
        any(),
        error: any(named: 'error'),
        stackTrace: any(named: 'stackTrace'),
        context: any(named: 'context'),
      ),
    ).thenReturn(null);

    await reporter.record(
      error,
      stackTrace,
      fatal: true,
      reason: 'test failure',
      context: const {'feature': 'movie_detail'},
    );

    verify(
      () => logger.error(
        'test failure',
        error: error,
        stackTrace: stackTrace,
        context: const {
          'crashProvider': 'logging',
          'fatal': true,
          'feature': 'movie_detail',
        },
      ),
    ).called(1);
  });

  test('CrashService maps platform errors to reporter contract', () async {
    final reporter = MockCrashReporter();
    final service = CrashService(reporter);
    final error = Exception('platform');
    final stackTrace = StackTrace.current;
    when(
      () => reporter.record(
        any(),
        any(),
        fatal: any(named: 'fatal'),
        reason: any(named: 'reason'),
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) async {});

    await service.recordPlatformError(error, stackTrace);

    verify(
      () => reporter.record(
        error,
        stackTrace,
        fatal: true,
        reason: 'Uncaught platform-dispatcher error',
        context: const {'source': 'PlatformDispatcher.onError'},
      ),
    ).called(1);
  });
}

class MockCrashReporter extends Mock implements CrashReporter {}
