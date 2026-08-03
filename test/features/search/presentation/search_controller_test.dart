import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:popcorn_movie_tracker/core/async/debounced_latest_task.dart';
import 'package:popcorn_movie_tracker/features/movies/domain/entities/movie.dart';
import 'package:popcorn_movie_tracker/features/movies/domain/entities/paged_movies.dart';
import 'package:popcorn_movie_tracker/features/movies/domain/repositories/movie_repository.dart';
import 'package:popcorn_movie_tracker/features/search/presentation/search_controller.dart';

class MockMovieRepository extends Mock implements MovieRepository {}

const movie1 = Movie(
  id: 1,
  title: 'Dune',
  overview: '',
  releaseDate: '2024-01-01',
  voteAverage: 8,
  genreIds: [],
);
const movie2 = Movie(
  id: 2,
  title: 'Dune Part Two',
  overview: '',
  releaseDate: '2024-03-01',
  voteAverage: 9,
  genreIds: [],
);

void main() {
  late MockMovieRepository repository;
  late MovieSearchController controller;

  setUp(() {
    repository = MockMovieRepository();
    controller = MovieSearchController(
      repository: repository,
      language: 'en-US',
      debouncer: DebouncedLatestTask<PagedMovies>(delay: Duration.zero),
    );
    addTearDown(controller.dispose);
  });

  test('initial discover publishes movies', () async {
    when(() => repository.discoverByGenre(null, 'en-US'))
        .thenAnswer((_) async => const [movie1]);

    await controller.initialize();

    expect(controller.state.movies, const [movie1]);
    expect(controller.state.isInitialLoading, isFalse);
  });

  test('query uses paginated search and records page metadata', () async {
    when(() => repository.searchPage('dune', 'en-US', 1)).thenAnswer(
      (_) async => const PagedMovies(
        items: [movie1],
        page: 1,
        totalPages: 2,
      ),
    );

    await controller.queryChanged('dune');

    expect(controller.state.movies, const [movie1]);
    expect(controller.state.page, 1);
    expect(controller.state.totalPages, 2);
    expect(controller.state.hasMore, isTrue);
  });

  test('loadMore appends next page and prevents duplicate page request',
      () async {
    when(() => repository.searchPage('dune', 'en-US', 1)).thenAnswer(
      (_) async => const PagedMovies(
        items: [movie1],
        page: 1,
        totalPages: 2,
      ),
    );
    when(() => repository.searchPage('dune', 'en-US', 2)).thenAnswer(
      (_) async => const PagedMovies(
        items: [movie2],
        page: 2,
        totalPages: 2,
      ),
    );

    await controller.queryChanged('dune');
    await Future.wait([controller.loadMore(), controller.loadMore()]);

    expect(controller.state.movies, const [movie1, movie2]);
    expect(controller.state.hasMore, isFalse);
    verify(() => repository.searchPage('dune', 'en-US', 2)).called(1);
  });

  test('preset loads selected feed and clears query', () async {
    when(() => repository.getTopRated('en-US'))
        .thenAnswer((_) async => const [movie2]);

    await controller.preset('topRated');

    expect(controller.state.query, isEmpty);
    expect(controller.state.movies, const [movie2]);
  });
}
