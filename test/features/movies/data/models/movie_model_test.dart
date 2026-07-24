import 'package:flutter_test/flutter_test.dart';
import 'package:popcorn_movie_tracker/features/movies/data/models/movie_model.dart';

void main() {
  group('MovieModel.fromJson', () {
    test(
        'maps list and detail fields including cast trailer and similar movies',
        () {
      final movie = MovieModel.fromJson({
        'id': 1,
        'title': 'Dune: Part Two',
        'overview': 'Overview',
        'poster_path': '/poster.jpg',
        'backdrop_path': '/backdrop.jpg',
        'release_date': '2024-03-01',
        'vote_average': 8.5,
        'genre_ids': [12, 878],
        'popularity': 123.4,
        'runtime': 166,
        'budget': 190000000,
        'revenue': 714000000,
        'vote_count': 5000,
        'original_language': 'en',
        'genres': [
          {'id': 878, 'name': 'Science Fiction'},
        ],
        'credits': {
          'cast': [
            {'name': 'Actor One', 'profile_path': '/actor.jpg'},
          ],
        },
        'videos': {
          'results': [
            {'site': 'YouTube', 'type': 'Trailer', 'key': 'abc123'},
          ],
        },
        'similar': {
          'results': [
            {
              'id': 2,
              'title': 'Similar Movie',
              'overview': '',
              'release_date': '2025-01-01',
              'vote_average': 7,
              'genre_ids': [12],
            },
          ],
        },
      });

      expect(movie.id, 1);
      expect(movie.title, 'Dune: Part Two');
      expect(movie.releaseYear, 2024);
      expect(movie.runtime, 166);
      expect(movie.genres, ['Science Fiction']);
      expect(movie.cast.single.name, 'Actor One');
      expect(movie.trailerKey, 'abc123');
      expect(movie.similar.single.title, 'Similar Movie');
    });

    test('normalizes missing values and blank title safely', () {
      final movie = MovieModel.fromJson({
        'id': 9,
        'title': '   ',
      });

      expect(movie.title, 'Untitled');
      expect(movie.overview, isEmpty);
      expect(movie.releaseDate, isEmpty);
      expect(movie.voteAverage, 0);
      expect(movie.genreIds, isEmpty);
      expect(movie.releaseYear, 0);
    });

    test('selects the first YouTube trailer or teaser only', () {
      final movie = MovieModel.fromJson({
        'videos': {
          'results': [
            {'site': 'Vimeo', 'type': 'Trailer', 'key': 'ignored'},
            {'site': 'YouTube', 'type': 'Clip', 'key': 'ignored2'},
            {'site': 'YouTube', 'type': 'Teaser', 'key': 'selected'},
          ],
        },
      });

      expect(movie.trailerKey, 'selected');
    });
  });
}
