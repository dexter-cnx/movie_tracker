import 'package:hive/hive.dart';
import 'package:popcorn_movie_tracker/features/watchlist/domain/watchlist_item.dart';

class WatchlistLocalDataSource {
  WatchlistLocalDataSource(this.box);
  static const boxName = 'watchlist_items';
  final Box<Map> box;

  List<WatchlistItem> getAll() => box.values.map(WatchlistItem.fromMap).toList()..sort((a,b)=>b.addedAt.compareTo(a.addedAt));
  Future<void> save(WatchlistItem item) => box.put(item.id, item.toMap());
  Future<void> delete(String id) => box.delete(id);
}
