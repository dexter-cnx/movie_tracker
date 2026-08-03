import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:popcorn_movie_tracker/core/theme/app_theme.dart';
import 'package:popcorn_movie_tracker/features/movie_detail/presentation/lifecycle_trailer_player.dart';
import 'package:popcorn_movie_tracker/features/movies/domain/entities/movie.dart';
import 'package:popcorn_movie_tracker/features/movies/presentation/movie_providers.dart';
import 'package:popcorn_movie_tracker/features/profile/presentation/profile_controller.dart';
import 'package:popcorn_movie_tracker/features/watchlist/domain/watchlist_item.dart';
import 'package:popcorn_movie_tracker/features/watchlist/presentation/watchlist_controller.dart';
import 'package:popcorn_movie_tracker/shared/widgets/clay_widgets.dart';
import 'package:uuid/uuid.dart';

class MovieDetailPage extends ConsumerWidget {
  const MovieDetailPage({
    super.key,
    required this.movieId,
  });

  final int movieId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = apiLanguage(context.locale.languageCode);
    final movieAsync = ref.watch(
      movieDetailProvider(MovieDetailArg(movieId, language)),
    );
    final autoplayTrailers = ref.watch(
      profileControllerProvider.select(
        (preferences) => preferences.autoplayTrailers,
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: movieAsync.when(
          data: (movie) => _content(
            context,
            ref,
            movie,
            autoplayTrailers: autoplayTrailers,
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(child: Text('networkUnavailable'.tr())),
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    WidgetRef ref,
    Movie movie, {
    required bool autoplayTrailers,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _backdrop(context, movie),
          const SizedBox(height: 20),
          Text(
            movie.title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _chip(Icons.star_rounded, movie.voteAverage.toStringAsFixed(1)),
              _chip(Icons.calendar_today_rounded, '${movie.releaseYear}'),
              _chip(
                Icons.schedule_rounded,
                '${movie.runtime ?? 0} ${'minutes'.tr()}',
              ),
              ...movie.genres.map((genre) => _chip(Icons.circle, genre)),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'ratingDistribution'.tr(),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          _ratingChart(movie),
          const SizedBox(height: 22),
          _statistics(context, movie),
          const SizedBox(height: 24),
          Text('overview'.tr(), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            movie.overview.isEmpty ? '-' : movie.overview,
            style:
                Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.55),
          ),
          const SizedBox(height: 24),
          Text('cast'.tr(), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _cast(movie),
          if (movie.trailerKey != null) ...[
            const SizedBox(height: 24),
            Text('trailer'.tr(), style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: LifecycleTrailerPlayer(
                key: ValueKey(movie.trailerKey),
                videoId: movie.trailerKey!,
                autoPlay: autoplayTrailers,
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _blackButton(
                  'addToWatchlist'.tr(),
                  () => _showWatchlistModal(context, ref, movie),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _blackButton(
                  'markWatched'.tr(),
                  () => _save(ref, movie, WatchStatus.watched),
                ),
              ),
            ],
          ),
          if (movie.similar.isNotEmpty) ...[
            const SizedBox(height: 26),
            Text(
              'similarMovies'.tr(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 190,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: movie.similar.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, index) {
                  final similar = movie.similar[index];
                  return GestureDetector(
                    onTap: () => context.push('/movie/${similar.id}'),
                    child: Poster(
                      path: similar.posterPath,
                      title: similar.title,
                      width: 120,
                      height: 180,
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _backdrop(BuildContext context, Movie movie) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Container(
            height: 250,
            width: double.infinity,
            color: AppColors.card,
            child: movie.backdropPath == null
                ? Center(
                    child: Text(
                      movie.title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  )
                : Image.network(
                    'https://image.tmdb.org/t/p/w500${movie.backdropPath}',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(
                        movie.title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                  ),
          ),
        ),
        Positioned(
          left: 12,
          top: 12,
          child: ClayIconButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => context.pop(),
          ),
        ),
      ],
    );
  }

  Widget _ratingChart(Movie movie) {
    return ClayCard(
      child: SizedBox(
        height: 150,
        child: BarChart(
          BarChartData(
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(10, (index) {
              final score = index + 1;
              final active = score <= movie.voteAverage;
              return BarChartGroupData(
                x: score,
                barRods: [
                  BarChartRodData(
                    toY: (active ? score + 1 : 4).toDouble(),
                    width: 13,
                    color: active ? AppColors.orange : AppColors.elevated,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _statistics(BuildContext context, Movie movie) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.7,
      children: [
        _stat(context, 'budget'.tr(), _money(movie.budget)),
        _stat(context, 'revenue'.tr(), _money(movie.revenue)),
        _stat(context, 'voteCount'.tr(), '${movie.voteCount ?? 0}'),
        _stat(
          context,
          'originalLanguage'.tr(),
          (movie.originalLanguage ?? '-').toUpperCase(),
        ),
      ],
    );
  }

  Widget _cast(Movie movie) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: movie.cast.isEmpty ? 4 : movie.cast.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, index) {
          final member = movie.cast.isEmpty ? null : movie.cast[index];
          final name = member?.name ?? 'Cast ${index + 1}';
          return SizedBox(
            width: 72,
            child: Column(
              children: [
                ClipOval(
                  child: Container(
                    width: 58,
                    height: 58,
                    color: AppColors.cardAlt,
                    child: member?.profilePath == null
                        ? const Icon(Icons.person_rounded)
                        : Image.network(
                            'https://image.tmdb.org/t/p/w185${member!.profilePath}',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.person_rounded),
                          ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _chip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color:
                icon == Icons.star_rounded ? AppColors.orange : AppColors.text,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String label, String value) {
    return ClayCard(
      padding: const EdgeInsets.all(14),
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
        ],
      ),
    );
  }

  String _money(int? value) {
    if (value == null || value == 0) return '-';
    return '\$${(value / 1000000).toStringAsFixed(1)}M';
  }

  Widget _blackButton(String text, VoidCallback onPressed) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.button,
        foregroundColor: AppColors.onButton,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: const StadiumBorder(),
      ),
      child: Text(text),
    );
  }

  Future<void> _showWatchlistModal(
    BuildContext context,
    WidgetRef ref,
    Movie movie,
  ) async {
    var status = WatchStatus.wantToWatch;
    double rating = 7;
    DateTime? watchedAt;
    final notesController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                22,
                20,
                MediaQuery.viewInsetsOf(context).bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'addToWatchlist'.tr(),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'selectStatus'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: WatchStatus.values.map((value) {
                        return ChoiceChip(
                          label: Text(value.name.tr()),
                          selected: status == value,
                          onSelected: (_) =>
                              setModalState(() => status = value),
                          showCheckmark: false,
                          selectedColor: AppColors.button,
                          labelStyle: TextStyle(
                            color: status == value
                                ? AppColors.onButton
                                : AppColors.text,
                          ),
                          side: BorderSide.none,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      '${'personalRating'.tr()}: ${rating.toStringAsFixed(0)}/10',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Slider(
                      value: rating,
                      min: 1,
                      max: 10,
                      divisions: 9,
                      activeColor: AppColors.orange,
                      onChanged: (value) => setModalState(() => rating = value),
                    ),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'notes'.tr(),
                        hintText: 'notesHint'.tr(),
                        filled: true,
                        fillColor: AppColors.cardAlt,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            watchedAt == null
                                ? 'noDate'.tr()
                                : watchedAt!.toIso8601String().split('T').first,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                              initialDate: watchedAt ?? DateTime.now(),
                            );
                            if (picked != null) {
                              setModalState(() => watchedAt = picked);
                            }
                          },
                          icon: const Icon(Icons.calendar_month_rounded),
                          label: Text('chooseDate'.tr()),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          await ref
                              .read(watchlistControllerProvider.notifier)
                              .save(
                                WatchlistItem(
                                  id: const Uuid().v4(),
                                  movieId: movie.id,
                                  title: movie.title,
                                  posterPath: movie.posterPath,
                                  backdropPath: movie.backdropPath,
                                  status: status,
                                  personalRating: rating,
                                  addedAt: DateTime.now(),
                                  watchedAt: watchedAt,
                                  notes: notesController.text.trim().isEmpty
                                      ? null
                                      : notesController.text.trim(),
                                  runtimeMinutes: movie.runtime,
                                  genre: movie.genres.isEmpty
                                      ? null
                                      : movie.genres.first,
                                ),
                              );
                          if (sheetContext.mounted) {
                            Navigator.of(sheetContext).pop();
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.button,
                          foregroundColor: AppColors.onButton,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: const StadiumBorder(),
                        ),
                        child: Text('save'.tr()),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    notesController.dispose();
  }

  Future<void> _save(WidgetRef ref, Movie movie, WatchStatus status) {
    return ref.read(watchlistControllerProvider.notifier).save(
          WatchlistItem(
            id: const Uuid().v4(),
            movieId: movie.id,
            title: movie.title,
            posterPath: movie.posterPath,
            backdropPath: movie.backdropPath,
            status: status,
            personalRating:
                status == WatchStatus.watched ? movie.voteAverage : null,
            addedAt: DateTime.now(),
            watchedAt: status == WatchStatus.watched ? DateTime.now() : null,
            runtimeMinutes: movie.runtime,
            genre: movie.genres.isEmpty ? null : movie.genres.first,
          ),
        );
  }
}
