import 'package:flutter_test/flutter_test.dart';
import 'package:popcorn_movie_tracker/core/async/debounced_latest_task.dart';

void main() {
  test('keeps only the newest rapid request result', () async {
    final task = DebouncedLatestTask<int>(
      delay: const Duration(milliseconds: 10),
    );
    addTearDown(task.dispose);

    final first = task.run(() async => 1);
    final second = task.run(() async => 2);

    expect(await first, isNull);
    expect(await second, 2);
  });

  test('an older asynchronous result is ignored', () async {
    final task = DebouncedLatestTask<int>(delay: Duration.zero);
    addTearDown(task.dispose);

    final first = task.run(() async {
      await Future<void>.delayed(const Duration(milliseconds: 30));
      return 1;
    });
    await Future<void>.delayed(const Duration(milliseconds: 1));
    final second = task.run(() async => 2);

    expect(await second, 2);
    expect(await first, isNull);
  });
}
