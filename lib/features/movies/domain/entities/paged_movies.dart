import 'package:popcorn_movie_tracker/features/movies/domain/entities/movie.dart';

class PagedMovies {
  const PagedMovies({
    required this.items,
    required this.page,
    required this.totalPages,
  });

  final List<Movie> items;
  final int page;
  final int totalPages;

  bool get hasMore => page < totalPages;

  PagedMovies append(PagedMovies next) => PagedMovies(
        items: [...items, ...next.items],
        page: next.page,
        totalPages: next.totalPages,
      );
}
