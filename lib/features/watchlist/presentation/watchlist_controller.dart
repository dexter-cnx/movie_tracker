import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:popcorn_movie_tracker/features/watchlist/data/watchlist_local_data_source.dart';
import 'package:popcorn_movie_tracker/features/watchlist/domain/watchlist_item.dart';

final watchlistDataSourceProvider = Provider((ref) => WatchlistLocalDataSource(Hive.box<Map>(WatchlistLocalDataSource.boxName)));
final watchlistControllerProvider = NotifierProvider<WatchlistController, List<WatchlistItem>>(WatchlistController.new);

class WatchlistController extends Notifier<List<WatchlistItem>> {
  WatchlistLocalDataSource get _source => ref.read(watchlistDataSourceProvider);
  @override List<WatchlistItem> build() => _source.getAll();
  Future<void> save(WatchlistItem item) async { await _source.save(item); state = _source.getAll(); }
  Future<void> delete(String id) async { await _source.delete(id); state = _source.getAll(); }
}
