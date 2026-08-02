import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:popcorn_movie_tracker/core/async/debounced_latest_task.dart';
import 'package:popcorn_movie_tracker/core/errors/app_failure.dart';
import 'package:popcorn_movie_tracker/features/movies/domain/entities/movie.dart';
import 'package:popcorn_movie_tracker/features/movies/domain/entities/paged_movies.dart';
import 'package:popcorn_movie_tracker/features/movies/domain/repositories/movie_repository.dart';
import 'package:popcorn_movie_tracker/features/movies/presentation/movie_providers.dart';

class MovieSearchState {
  const MovieSearchState({
    this.query = '',
    this.genreId,
    this.movies = const [],
    this.page = 1,
    this.totalPages = 1,
    this.isInitialLoading = false,
    this.isLoadingMore = false,
    this.failure,
  });

  final String query;
  final int? genreId;
  final List<Movie> movies;
  final int page;
  final int totalPages;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final AppFailure? failure;

  bool get hasMore => query.trim().isNotEmpty && page < totalPages;

  MovieSearchState copyWith({
    String? query,
    int? genreId,
    bool clearGenre = false,
    List<Movie>? movies,
    int? page,
    int? totalPages,
    bool? isInitialLoading,
    bool? isLoadingMore,
    AppFailure? failure,
    bool clearFailure = false,
  }) {
    return MovieSearchState(
      query: query ?? this.query,
      genreId: clearGenre ? null : (genreId ?? this.genreId),
      movies: movies ?? this.movies,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}

class MovieSearchController extends StateNotifier<MovieSearchState> {
  MovieSearchController({
    required this.repository,
    required this.language,
    DebouncedLatestTask<PagedMovies>? debouncer,
  })  : _debouncer = debouncer ?? DebouncedLatestTask<PagedMovies>(),
        super(const MovieSearchState());

  final MovieRepository repository;
  final String language;
  final DebouncedLatestTask<PagedMovies> _debouncer;

  Future<void> initialize() async {
    if (state.movies.isNotEmpty || state.isInitialLoading) return;
    await discover();
  }

  Future<void> queryChanged(String value) async {
    final query = value.trim();
    state = state.copyWith(
      query: query,
      clearGenre: query.isNotEmpty,
      isInitialLoading: true,
      isLoadingMore: false,
      clearFailure: true,
      page: 1,
      totalPages: 1,
      movies: query.isEmpty ? state.movies : const [],
    );

    if (query.isEmpty) {
      _debouncer.cancel();
      await discover();
      return;
    }

    try {
      final result = await _debouncer.run(
        () => repository.searchPage(query, language, 1),
      );
      if (result == null || state.query != query) return;
      state = state.copyWith(
        movies: result.items,
        page: result.page,
        totalPages: result.totalPages,
        isInitialLoading: false,
        clearFailure: true,
      );
    } on Object catch (error) {
      if (state.query != query) return;
      state = state.copyWith(
        isInitialLoading: false,
        failure: mapExceptionToFailure(error),
      );
    }
  }

  Future<void> discover({int? genreId}) async {
    _debouncer.cancel();
    state = state.copyWith(
      query: '',
      genreId: genreId,
      clearGenre: genreId == null,
      isInitialLoading: true,
      isLoadingMore: false,
      clearFailure: true,
      page: 1,
      totalPages: 1,
    );

    try {
      final movies = await repository.discoverByGenre(genreId, language);
      state = state.copyWith(
        movies: movies,
        isInitialLoading: false,
        clearFailure: true,
      );
    } on Object catch (error) {
      state = state.copyWith(
        isInitialLoading: false,
        failure: mapExceptionToFailure(error),
      );
    }
  }

  Future<void> preset(String preset) async {
    _debouncer.cancel();
    state = state.copyWith(
      query: '',
      clearGenre: true,
      isInitialLoading: true,
      isLoadingMore: false,
      clearFailure: true,
      page: 1,
      totalPages: 1,
    );

    try {
      final List<Movie> movies;
      switch (preset) {
        case 'trending':
          movies = await repository.getTrending(language);
          break;
        case 'topRated':
          movies = await repository.getTopRated(language);
          break;
        case 'upcoming':
          movies = await repository.getUpcoming(language);
          break;
        default:
          movies = await repository.getNowPlaying(language);
      }
      state = state.copyWith(
        movies: movies,
        isInitialLoading: false,
        clearFailure: true,
      );
    } on Object catch (error) {
      state = state.copyWith(
        isInitialLoading: false,
        failure: mapExceptionToFailure(error),
      );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isInitialLoading || state.isLoadingMore) return;
    final query = state.query;
    final nextPage = state.page + 1;
    state = state.copyWith(isLoadingMore: true, clearFailure: true);

    try {
      final next = await repository.searchPage(query, language, nextPage);
      if (state.query != query) return;
      state = state.copyWith(
        movies: [...state.movies, ...next.items],
        page: next.page,
        totalPages: next.totalPages,
        isLoadingMore: false,
      );
    } on Object catch (error) {
      state = state.copyWith(
        isLoadingMore: false,
        failure: mapExceptionToFailure(error),
      );
    }
  }

  Future<void> retry() {
    if (state.query.isNotEmpty) return queryChanged(state.query);
    return discover(genreId: state.genreId);
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }
}

final movieSearchControllerProvider = StateNotifierProvider.autoDispose
    .family<MovieSearchController, MovieSearchState, String>((ref, language) {
  return MovieSearchController(
    repository: ref.watch(movieRepositoryProvider),
    language: language,
  );
});
