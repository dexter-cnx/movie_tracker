import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:popcorn_movie_tracker/core/theme/app_theme.dart';
import 'package:popcorn_movie_tracker/features/movies/domain/entities/movie.dart';
import 'package:popcorn_movie_tracker/features/movies/presentation/movie_providers.dart';
import 'package:popcorn_movie_tracker/shared/widgets/clay_widgets.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  int? genre;
  List<Movie> movies = const [];
  bool loading = false;
  Movie? roulette;

  Future<void> load([String query = '']) async {
    if (loading) return;
    setState(() => loading = true);

    try {
      final repository = ref.read(movieRepositoryProvider);
      final language = apiLanguage(context.locale.languageCode);
      final result = query.trim().isEmpty
          ? await repository.discoverByGenre(genre, language)
          : await repository.search(query, language);

      if (!mounted) return;
      setState(() => movies = result);
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (movies.isEmpty && !loading) {
      Future.microtask(load);
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = apiLanguage(context.locale.languageCode);
    final genres = ref.watch(genresProvider(language));

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'explore'.tr(),
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 18),
            TextField(
              onSubmitted: load,
              decoration: InputDecoration(
                hintText: 'searchHint'.tr(),
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: const Icon(Icons.tune_rounded),
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
                    _genreChip(null, 'allGenres'.tr()),
                    ...items.map((item) => _genreChip(item.id, item.name)),
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
                      onPressed: () => _preset(key),
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
                    onPressed: () {
                      if (movies.isEmpty) return;
                      setState(() {
                        roulette = movies[Random().nextInt(movies.length)];
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
            if (loading)
              const Center(child: CircularProgressIndicator())
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: .67,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                itemCount: movies.length,
                itemBuilder: (_, index) {
                  final movie = movies[index];
                  return GestureDetector(
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
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _genreChip(int? id, String name) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(name),
        selected: genre == id,
        onSelected: (_) {
          setState(() => genre = id);
          load();
        },
        showCheckmark: false,
        selectedColor: AppColors.button,
        labelStyle: TextStyle(
          color: genre == id ? AppColors.onButton : AppColors.text,
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide.none,
        backgroundColor: AppColors.card,
      ),
    );
  }

  Future<void> _preset(String preset) async {
    if (loading) return;
    setState(() => loading = true);

    try {
      final repository = ref.read(movieRepositoryProvider);
      final language = apiLanguage(context.locale.languageCode);

      final List<Movie> result;
      switch (preset) {
        case 'trending':
          result = await repository.getTrending(language);
          break;
        case 'topRated':
          result = await repository.getTopRated(language);
          break;
        case 'upcoming':
          result = await repository.getUpcoming(language);
          break;
        default:
          result = await repository.getNowPlaying(language);
          break;
      }

      if (!mounted) return;
      setState(() => movies = result);
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }
}
