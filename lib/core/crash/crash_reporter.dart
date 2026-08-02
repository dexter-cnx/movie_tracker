import 'package:popcorn_movie_tracker/core/logging/app_logger.dart';

abstract interface class CrashReporter {
  Future<void> record(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
    String? reason,
  });
}

class LoggingCrashReporter implements CrashReporter {
  const LoggingCrashReporter(this.logger);

  final AppLogger logger;

  @override
  Future<void> record(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
    String? reason,
  }) async {
    logger.error(
      reason ?? 'Unhandled application error',
      error: error,
      stackTrace: stackTrace,
      context: {'fatal': fatal},
    );
  }
}
