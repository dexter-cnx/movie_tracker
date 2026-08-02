import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:popcorn_movie_tracker/core/crash/crash_reporter.dart';
import 'package:popcorn_movie_tracker/core/logging/app_logger.dart';

class MockAppLogger extends Mock implements AppLogger {}
class MockCrashReporter extends Mock implements CrashReporter {}

void main() {
  late MockAppLogger logger;
  late LoggingCrashReporter reporter;

  setUpAll(() {
    registerFallbackValue(Exception('fallback'));
    registerFallbackValue(StackTrace.empty);
    registerFallbackValue(<String, Object?>{});
  });

  setUp(() {
    logger = MockAppLogger();
    reporter = LoggingCrashReporter(logger);
  });

  test('initializes logging crash reporter', () async {
    when(() => logger.info(any(), context: any(named: 'context')))
        .thenReturn(null);

    await reporter.initialize();

    verify(() => logger.info(any(), context: any(named: 'context'))).called(1);
  });

  test('records fatal error with context', () async {
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

  test('CrashService maps platform errors', () async {
    final mockReporter = MockCrashReporter();
    final service = CrashService(mockReporter);
    final error = Exception('platform');
    final stackTrace = StackTrace.current;
    when(
      () => mockReporter.record(
        any(),
        any(),
        fatal: any(named: 'fatal'),
        reason: any(named: 'reason'),
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) async {});

    await service.recordPlatformError(error, stackTrace);

    verify(
      () => mockReporter.record(
        error,
        stackTrace,
        fatal: true,
        reason: 'Uncaught platform-dispatcher error',
        context: const {'source': 'PlatformDispatcher.onError'},
      ),
    ).called(1);
  });
}
