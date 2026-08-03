import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:popcorn_movie_tracker/core/layout/responsive_layout.dart';
import 'package:popcorn_movie_tracker/core/theme/app_theme.dart';
import 'package:popcorn_movie_tracker/features/movies/domain/entities/movie.dart';
import 'package:popcorn_movie_tracker/features/movies/domain/entities/movie_load_result.dart';
import 'package:popcorn_movie_tracker/features/movies/presentation/movie_providers.dart';
import 'package:popcorn_movie_tracker/features/profile/presentation/profile_controller.dart';
import 'package:popcorn_movie_tracker/features/watchlist/presentation/watchlist_controller.dart';
import 'package:popcorn_movie_tracker/shared/widgets/clay_widgets.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final horizontalPadding = ResponsiveLayout.horizontalPadding(size);
    final lang = apiLanguage(context.locale.languageCode);
    final trending = ref.watch(trendingFeedProvider(lang));
    final watchlist = ref.watch(watchlistControllerProvider);
    final profile = ref.watch(profileControllerProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          18,
          horizontalPadding,
          120,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'welcome'.tr(
                          namedArgs: {'name': profile.displayName},
                        ),
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'hotToday'.tr(),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const ClayIconButton(icon: Icons.notifications_none_rounded),
                const SizedBox(width: 10),
                ClayIconButton(
                  icon: Icons.calendar_month_rounded,
                  onTap: () => context.push('/calendar'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => context.go('/explore'),
              child: Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(27),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .04),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'searchHint'.tr(),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const ClayIconButton(icon: Icons.tune_rounded),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            _WatchStatsCard(onPressed: () => context.go('/watchlist')),
            const SizedBox(height: 28),
            _sectionHeader(context, 'trendingNow'.tr()),
            const SizedBox(height: 12),
            trending.when(
              data: (result) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (result.source == MovieDataSource.staleCache ||
                      result.source == MovieDataSource.mock)
                    _FeedStatusBanner(
                      result: result,
                      onRetry: () => ref.invalidate(trendingFeedProvider(lang)),
                    ),
                  if (result.source == MovieDataSource.freshCache)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        'freshCacheNotice'.tr(),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  _TrendingList(movies: result.movies),
                ],
              ),
              loading: () => const SizedBox(
                height: 285,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => _BlockingError(
                message: error.toString(),
                onRetry: () => ref.invalidate(trendingFeedProvider(lang)),
              ),
            ),
            const SizedBox(height: 28),
            _sectionHeader(
              context,
              'myWatchlist'.tr(),
              action: TextButton(
                onPressed: () => context.go('/watchlist'),
                child: Text('seeAll'.tr()),
              ),
            ),
            const SizedBox(height: 10),
            if (watchlist.isEmpty)
              ...List.generate(
                3,
                (index) => _watchRow(
                  context,
                  ['Dune: Part Two', 'Inside Out 2', 'The Wild Robot'][index],
                  [
                    'upcoming'.tr(),
                    'watched'.tr(),
                    '60% ${'watched'.tr()}',
                  ][index],
                ),
              )
            else
              ...watchlist.take(4).map(
                    (item) => _watchRow(
                      context,
                      item.title,
                      item.status.name.tr(),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(
    BuildContext context,
    String title, {
    Widget? action,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (action != null) action,
      ],
    );
  }

  Widget _watchRow(BuildContext context, String title, String status) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClayCard(
        padding: const EdgeInsets.all(12),
        radius: 22,
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.cardAlt,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.movie_rounded),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(status, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            Text(
              '${'today'.tr()}: 8:15pm',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _WatchStatsCard extends StatelessWidget {
  const _WatchStatsCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'watchStats'.tr(),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  '+3.45%',
                  style: TextStyle(
                    color: AppColors.green,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 90,
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(
                  7,
                  (index) => BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: [3, 5, 4, 7, 6, 8, 5][index].toDouble(),
                        width: 10,
                        borderRadius: BorderRadius.circular(4),
                        color:
                            index == 5 ? AppColors.orange : AppColors.elevated,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),
          FilledButton(onPressed: onPressed, child: Text('checkNow'.tr())),
        ],
      ),
    );
  }
}

class _TrendingList extends StatelessWidget {
  const _TrendingList({required this.movies});

  final List<Movie> movies;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 285,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: movies.take(6).length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final movie = movies[index];
          return GestureDetector(
            onTap: () => context.push('/movie/${movie.id}'),
            child: SizedBox(
              width: 165,
              child: ClayCard(
                padding: const EdgeInsets.all(10),
                radius: 25,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Poster(
                      path: movie.posterPath,
                      width: 145,
                      height: 175,
                      title: movie.title,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            movie.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Text(
                          movie.voteAverage.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      movie.genres.isEmpty ? 'movie'.tr() : movie.genres.first,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (movie.popularity / 100).clamp(0, 1),
                        minHeight: 5,
                        backgroundColor: AppColors.elevated,
                        color: AppColors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FeedStatusBanner extends StatelessWidget {
  const _FeedStatusBanner({required this.result, required this.onRetry});

  final MovieLoadResult result;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final message = result.source == MovieDataSource.staleCache
        ? 'staleCacheNotice'.tr()
        : 'networkUnavailable'.tr();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.orange.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_rounded, color: AppColors.orange),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
            TextButton(onPressed: onRetry, child: Text('retry'.tr())),
          ],
        ),
      ),
    );
  }
}

class _BlockingError extends StatelessWidget {
  const _BlockingError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, size: 36),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: Text('retry'.tr())),
        ],
      ),
    );
  }
}
