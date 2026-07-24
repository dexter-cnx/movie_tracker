import 'package:flutter_test/flutter_test.dart';
import 'package:popcorn_movie_tracker/features/watchlist/domain/watchlist_item.dart';

void main() {
  group('WatchlistItem', () {
    test('round-trips all persisted fields through map serialization', () {
      final item = WatchlistItem(
        id: 'item-1',
        movieId: 42,
        title: 'Movie',
        posterPath: '/poster.jpg',
        backdropPath: '/backdrop.jpg',
        status: WatchStatus.watched,
        personalRating: 8.5,
        addedAt: DateTime.utc(2026, 7, 1),
        watchedAt: DateTime.utc(2026, 7, 2),
        notes: 'Great movie',
        runtimeMinutes: 120,
        genre: 'Drama',
      );

      final restored = WatchlistItem.fromMap(item.toMap());

      expect(restored.id, item.id);
      expect(restored.movieId, item.movieId);
      expect(restored.title, item.title);
      expect(restored.posterPath, item.posterPath);
      expect(restored.backdropPath, item.backdropPath);
      expect(restored.status, WatchStatus.watched);
      expect(restored.personalRating, 8.5);
      expect(restored.addedAt, item.addedAt);
      expect(restored.watchedAt, item.watchedAt);
      expect(restored.notes, 'Great movie');
      expect(restored.runtimeMinutes, 120);
      expect(restored.genre, 'Drama');
    });

    test('falls back to wantToWatch when stored status is unknown', () {
      final item = WatchlistItem.fromMap({
        'id': 'item-1',
        'movieId': 1,
        'title': 'Movie',
        'status': 'unsupported',
        'addedAt': DateTime.utc(2026, 7, 1).toIso8601String(),
      });

      expect(item.status, WatchStatus.wantToWatch);
    });

    test('accepts numeric personal rating values', () {
      final item = WatchlistItem.fromMap({
        'id': 'item-1',
        'movieId': 1,
        'title': 'Movie',
        'status': 'favorite',
        'personalRating': 9,
        'addedAt': DateTime.utc(2026, 7, 1).toIso8601String(),
      });

      expect(item.personalRating, 9.0);
    });
  });
}
