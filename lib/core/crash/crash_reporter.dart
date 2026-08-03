import 'package:popcorn_movie_tracker/core/logging/app_logger.dart';

/// Vendor-neutral crash reporting contract.
///
/// Feature and bootstrap code depend only on this interface. A future
/// Firebase Crashlytics or Sentry adapter can implement the same methods
/// without changing callers.
abstract interface class CrashReporter {
  Future<void> initialize();

  Future<void> record(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
    String? reason,
    Map<String, Object?> context = const {},
  });

  Future<void> breadcrumb(
    String message, {
    Map<String, Object?> context = const {},
  });

  Future<void> setUser(String? userId);

  Future<void> setContext(String key, Object? value);
}

/// Current crash reporter used by the portfolio application.
///
/// It records crash events through [AppLogger], so the full crash pipeline can
/// be exercised without Firebase/Sentry credentials. Sensitive values remain
/// protected by the logger's redaction policy.
class LoggingCrashReporter implements CrashReporter {
  const LoggingCrashReporter(this.logger);

  final AppLogger logger;

  @override
  Future<void> initialize() async {
    logger.info(
      'Crash reporting initialized',
      context: {
        'provider': 'logging',
        'futureAdapters': 'firebase_crashlytics,sentry',
      },
    );
  }

  @override
  Future<void> record(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
    String? reason,
    Map<String, Object?> context = const {},
  }) async {
    logger.error(
      reason ?? 'Unhandled application error',
      error: error,
      stackTrace: stackTrace,
      context: {
        'crashProvider': 'logging',
        'fatal': fatal,
        ...context,
      },
    );
  }

  @override
  Future<void> breadcrumb(
    String message, {
    Map<String, Object?> context = const {},
  }) async {
    logger.info(
      'Crash breadcrumb: $message',
      context: {
        'crashProvider': 'logging',
        ...context,
      },
    );
  }

  @override
  Future<void> setUser(String? userId) async {
    logger.info(
      'Crash user context updated',
      context: {
        'crashProvider': 'logging',
        'userId': userId ?? '<cleared>',
      },
    );
  }

  @override
  Future<void> setContext(String key, Object? value) async {
    logger.debug(
      'Crash custom context updated',
      context: {
        'crashProvider': 'logging',
        'contextKey': key,
        'contextValue': value,
      },
    );
  }
}

/// Application-facing crash service.
///
/// Keep this object at the composition root and pass only the
/// [CrashReporter] implementation that matches the environment. To connect a
/// real provider later, implement `FirebaseCrashReporter` or
/// `SentryCrashReporter` and change only the construction in `main.dart`.
class CrashService {
  const CrashService(this.reporter);

  final CrashReporter reporter;

  Future<void> initialize() => reporter.initialize();

  Future<void> recordFlutterError(FlutterErrorDetailsAdapter details) {
    return reporter.record(
      details.exception,
      details.stackTrace,
      fatal: false,
      reason: details.reason,
      context: const {'source': 'FlutterError.onError'},
    );
  }

  Future<void> recordPlatformError(Object error, StackTrace stackTrace) {
    return reporter.record(
      error,
      stackTrace,
      fatal: true,
      reason: 'Uncaught platform-dispatcher error',
      context: const {'source': 'PlatformDispatcher.onError'},
    );
  }

  Future<void> breadcrumb(
    String message, {
    Map<String, Object?> context = const {},
  }) =>
      reporter.breadcrumb(message, context: context);

  Future<void> setUser(String? userId) => reporter.setUser(userId);

  Future<void> setContext(String key, Object? value) =>
      reporter.setContext(key, value);
}

/// Small framework-independent adapter used by [CrashService].
class FlutterErrorDetailsAdapter {
  const FlutterErrorDetailsAdapter({
    required this.exception,
    required this.stackTrace,
    this.reason,
  });

  final Object exception;
  final StackTrace stackTrace;
  final String? reason;
}
