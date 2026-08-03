import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:popcorn_movie_tracker/core/layout/responsive_layout.dart';
import 'package:popcorn_movie_tracker/core/theme/app_theme.dart';
import 'package:popcorn_movie_tracker/features/movies/domain/entities/movie.dart';
import 'package:popcorn_movie_tracker/features/movies/presentation/movie_providers.dart';
import 'package:popcorn_movie_tracker/features/search/presentation/search_controller.dart';
import 'package:popcorn_movie_tracker/shared/widgets/clay_widgets.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _queryController = TextEditingController();
  final _scrollController = ScrollController();
  Movie? roulette;
  String? _initializedLanguage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final language = apiLanguage(context.locale.languageCode);
    if (_initializedLanguage == language) return;
    _initializedLanguage = language;
    Future.microtask(
      () => ref
          .read(movieSearchControllerProvider(language).notifier)
          .initialize(),
    );
  }

  @override
  void dispose() {
    _queryController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.extentAfter > 600) return;
    final language = apiLanguage(context.locale.languageCode);
    ref.read(movieSearchControllerProvider(language).notifier).loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final ratioClass = ResponsiveLayout.classOf(size);
    final columns = ResponsiveLayout.gridColumns(size);
    final horizontalPadding = ResponsiveLayout.horizontalPadding(size);
    final language = apiLanguage(context.locale.languageCode);
    final genres = ref.watch(genresProvider(language));
    final state = ref.watch(movieSearchControllerProvider(language));
    final controller =
        ref.read(movieSearchControllerProvider(language).notifier);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: controller.retry,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                20,
                horizontalPadding,
                0,
              ),
              sliver: SliverList.list(
                children: [
                  Text(
                    'explore'.tr(),
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _queryController,
                    onChanged: controller.queryChanged,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'searchHint'.tr(),
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: state.query.isEmpty
                          ? const Icon(Icons.tune_rounded)
                          : IconButton(
                              tooltip: 'cancel'.tr(),
                              onPressed: () {
                                _queryController.clear();
                                controller.queryChanged('');
                              },
                              icon: const Icon(Icons.clear_rounded),
                            ),
                      filled: true,
                      fillColor: AppColors.cardAlt,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),
                  const SizedBox(height: 18),
                  genres.when(
                    data: (items) => SizedBox(
                      height: 44,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _genreChip(
                            id: null,
                            name: 'allGenres'.tr(),
                            selectedId: state.genreId,
                            onSelected: () => controller.discover(),
                          ),
                          ...items.map(
                            (item) => _genreChip(
                              id: item.id,
                              name: item.name,
                              selectedId: state.genreId,
                              onSelected: () => controller.discover(
                                genreId: item.id,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    loading: () => const SizedBox(height: 44),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'discoverByMood'.tr(),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['trending', 'topRated', 'upcoming', 'nowPlaying']
                        .map(
                          (key) => ActionChip(
                            label: Text(key.tr()),
                            onPressed: () {
                              _queryController.clear();
                              controller.preset(key);
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  ClayCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'movieRoulette'.tr(),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                roulette?.title ?? 'spinMovie'.tr(),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        FilledButton(
                          onPressed: state.movies.isEmpty
                              ? null
                              : () {
                                  setState(() {
                                    roulette = state.movies[
                                        Random().nextInt(state.movies.length)];
                                  });
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.button,
                            foregroundColor: AppColors.onButton,
                            shape: const StadiumBorder(),
                          ),
                          child: const Icon(Icons.casino_rounded),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (state.failure != null && state.movies.isEmpty)
                    _ErrorCard(
                      message: state.failure!.message,
                      onRetry: controller.retry,
                    )
                  else if (state.isInitialLoading && state.movies.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(36),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (state.movies.isEmpty)
                    ClayCard(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Text('noMovies'.tr()),
                        ),
                      ),
                    ),
                  if (state.failure != null && state.movies.isNotEmpty) ...[
                    _InlineLoadMoreError(
                      message: state.failure!.message,
                      onRetry: controller.loadMore,
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
            if (state.movies.isNotEmpty)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  0,
                  horizontalPadding,
                  20,
                ),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    childAspectRatio:
                        ratioClass == DeviceRatioClass.wide ? .74 : .67,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _MovieCard(movie: state.movies[index]),
                    childCount: state.movies.length,
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: state.isLoadingMore
                    ? const Padding(
                        key: ValueKey('loading-more'),
                        padding: EdgeInsets.fromLTRB(0, 12, 0, 120),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : SizedBox(
                        key: const ValueKey('bottom-space'),
                        height: state.hasMore ? 80 : 120,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _genreChip({
    required int? id,
    required String name,
    required int? selectedId,
    required VoidCallback onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(name),
        selected: selectedId == id && _queryController.text.trim().isEmpty,
        onSelected: (_) {
          _queryController.clear();
          onSelected();
        },
        showCheckmark: false,
        selectedColor: AppColors.button,
        labelStyle: TextStyle(
          color: selectedId == id && _queryController.text.trim().isEmpty
              ? AppColors.onButton
              : AppColors.text,
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide.none,
        backgroundColor: AppColors.card,
      ),
    );
  }
}

class _MovieCard extends StatelessWidget {
  const _MovieCard({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: movie.title,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => context.push('/movie/${movie.id}'),
        child: ClayCard(
          padding: const EdgeInsets.all(10),
          radius: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Poster(
                  path: movie.posterPath,
                  title: movie.title,
                  width: double.infinity,
                  height: 220,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                movie.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              Text(
                '⭐ ${movie.voteAverage.toStringAsFixed(1)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 36),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: Text('retry'.tr())),
        ],
      ),
    );
  }
}

class _InlineLoadMoreError extends StatelessWidget {
  const _InlineLoadMoreError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardAlt,
      borderRadius: BorderRadius.circular(18),
      child: ListTile(
        leading: const Icon(Icons.error_outline_rounded),
        title: Text(message, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: TextButton(onPressed: onRetry, child: Text('retry'.tr())),
      ),
    );
  }
}
