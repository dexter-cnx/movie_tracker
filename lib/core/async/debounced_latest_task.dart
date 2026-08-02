import 'dart:async';

/// Debounces user input and prevents an older asynchronous result from
/// overwriting a newer request.
///
/// This is intentionally transport-agnostic. Dio cancellation may still be
/// added inside the operation, while this coordinator guarantees presentation
/// correctness even when an upstream request cannot be cancelled immediately.
class DebouncedLatestTask<T> {
  DebouncedLatestTask({this.delay = const Duration(milliseconds: 400)});

  final Duration delay;
  Timer? _timer;
  int _generation = 0;
  bool _disposed = false;

  Future<T?> run(Future<T> Function() operation) {
    final completer = Completer<T?>();
    final generation = ++_generation;
    _timer?.cancel();

    _timer = Timer(delay, () async {
      if (_disposed || generation != _generation) {
        if (!completer.isCompleted) completer.complete(null);
        return;
      }

      try {
        final result = await operation();
        if (_disposed || generation != _generation) {
          completer.complete(null);
        } else {
          completer.complete(result);
        }
      } on Object catch (error, stackTrace) {
        if (_disposed || generation != _generation) {
          completer.complete(null);
        } else {
          completer.completeError(error, stackTrace);
        }
      }
    });

    return completer.future;
  }

  void cancel() {
    _generation++;
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    _disposed = true;
    cancel();
  }
}
