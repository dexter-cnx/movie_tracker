import 'dart:async';

/// Debounces user input and prevents an older asynchronous result from
/// overwriting a newer request.
///
/// This is transport-agnostic. Dio cancellation can still be added inside the
/// operation, while this coordinator guarantees presentation correctness even
/// when an upstream request cannot be cancelled immediately.
class DebouncedLatestTask<T> {
  DebouncedLatestTask({this.delay = const Duration(milliseconds: 400)});

  final Duration delay;
  Timer? _timer;
  Completer<T?>? _pendingCompleter;
  int _generation = 0;
  bool _disposed = false;

  Future<T?> run(Future<T> Function() operation) {
    if (_disposed) {
      return Future<T?>.value(null);
    }

    _completePendingAsCancelled();
    _timer?.cancel();

    final completer = Completer<T?>();
    _pendingCompleter = completer;
    final generation = ++_generation;

    _timer = Timer(delay, () async {
      _timer = null;
      if (_disposed || generation != _generation) {
        _complete(completer, null);
        return;
      }

      try {
        final result = await operation();
        if (_disposed || generation != _generation) {
          _complete(completer, null);
        } else {
          _complete(completer, result);
        }
      } on Object catch (error, stackTrace) {
        if (_disposed || generation != _generation) {
          _complete(completer, null);
        } else if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      } finally {
        if (identical(_pendingCompleter, completer)) {
          _pendingCompleter = null;
        }
      }
    });

    return completer.future;
  }

  void cancel() {
    _generation++;
    _timer?.cancel();
    _timer = null;
    _completePendingAsCancelled();
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    cancel();
  }

  void _completePendingAsCancelled() {
    final pending = _pendingCompleter;
    _pendingCompleter = null;
    if (pending != null && !pending.isCompleted) {
      pending.complete(null);
    }
  }

  void _complete(Completer<T?> completer, T? value) {
    if (!completer.isCompleted) completer.complete(value);
  }
}
