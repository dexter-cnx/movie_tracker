import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:popcorn_movie_tracker/core/theme/app_theme.dart';
import 'package:popcorn_movie_tracker/features/watchlist/domain/watchlist_item.dart';
import 'package:popcorn_movie_tracker/features/watchlist/presentation/watchlist_controller.dart';
import 'package:popcorn_movie_tracker/shared/widgets/clay_widgets.dart';

class WatchlistPage extends ConsumerWidget {
  const WatchlistPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(watchlistControllerProvider);
    final watched =
        items.where((item) => item.status == WatchStatus.watched).toList();

    final totalMinutes = watched.fold<int>(
      0,
      (sum, item) => sum + (item.runtimeMinutes ?? 0),
    );
    final hours = totalMinutes / 60;

    final ratings = watched
        .where((item) => item.personalRating != null)
        .map((item) => item.personalRating!)
        .toList();
    final averageRating = ratings.isEmpty
        ? 0.0
        : ratings.reduce((a, b) => a + b) / ratings.length;

    final genreCounts = <String, int>{};
    for (final item in watched) {
      final genre = item.genre;
      if (genre != null) {
        genreCounts[genre] = (genreCounts[genre] ?? 0) + 1;
      }
    }

    final favoriteGenre = genreCounts.isEmpty
        ? '-'
        : (genreCounts.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .first
            .key;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'myList'.tr(),
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.55,
              children: [
                _stat(
                  context,
                  'totalMoviesWatched'.tr(),
                  '${watched.length}',
                ),
                _stat(context, 'totalHours'.tr(), hours.toStringAsFixed(1)),
                _stat(
                  context,
                  'averageRating'.tr(),
                  averageRating.toStringAsFixed(1),
                ),
                _stat(context, 'favoriteGenre'.tr(), favoriteGenre),
              ],
            ),
            const SizedBox(height: 26),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'myWatchlist'.tr(),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const ClayIconButton(icon: Icons.grid_view_rounded),
              ],
            ),
            const SizedBox(height: 14),
            if (items.isEmpty)
              ClayCard(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Text('noMovies'.tr()),
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: .65,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                itemCount: items.length,
                itemBuilder: (_, index) {
                  final item = items[index];
                  final progress = ((item.personalRating ?? 0) / 10)
                      .clamp(0.0, 1.0)
                      .toDouble();

                  return ClayCard(
                    padding: const EdgeInsets.all(10),
                    radius: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Poster(
                            path: item.posterPath,
                            title: item.title,
                            width: double.infinity,
                            height: 220,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.status.name.tr(),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: AppColors.elevated,
                            color: AppColors.orange,
                            minHeight: 5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _stat(BuildContext context, String label, String value) {
    return ClayCard(
      padding: const EdgeInsets.all(15),
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 7),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}
