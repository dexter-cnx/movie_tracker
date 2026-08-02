import 'dart:developer' as developer;

abstract interface class AppLogger {
  void debug(String message, {Map<String, Object?> context = const {}});
  void info(String message, {Map<String, Object?> context = const {}});
  void warning(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  });
  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  });
}

class DeveloperAppLogger implements AppLogger {
  const DeveloperAppLogger();

  static const _redactedKeys = {
    'authorization',
    'token',
    'accessToken',
    'refreshToken',
    'password',
    'email',
  };

  @override
  void debug(String message, {Map<String, Object?> context = const {}}) {
    _write('DEBUG', message, context: context);
  }

  @override
  void info(String message, {Map<String, Object?> context = const {}}) {
    _write('INFO', message, context: context);
  }

  @override
  void warning(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) {
    _write(
      'WARNING',
      message,
      error: error,
      stackTrace: stackTrace,
      context: context,
    );
  }

  @override
  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) {
    _write(
      'ERROR',
      message,
      error: error,
      stackTrace: stackTrace,
      context: context,
    );
  }

  void _write(
    String level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) {
    final safeContext = <String, Object?>{
      for (final entry in context.entries)
        entry.key: _redactedKeys.contains(entry.key) ? '<redacted>' : entry.value,
    };

    developer.log(
      '$level $message${safeContext.isEmpty ? '' : ' $safeContext'}',
      name: 'popcorn',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
