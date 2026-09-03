import 'package:flutter_test/flutter_test.dart';
import 'package:popcorn_movie_tracker/features/movies/data/models/tmdb_dto.dart';

void main() {
  test('maps TMDB detail DTO into the domain movie', () {
    final dto = TmdbMovieDto.fromJson({
      'id': 42,
      'title': '  Popcorn Test  ',
      'overview': 'Overview',
      'poster_path': '/poster.jpg',
      'backdrop_path': '/backdrop.jpg',
      'release_date': '2026-09-04',
      'vote_average': 8.5,
      'genre_ids': [12, 878],
      'popularity': 99.2,
      'runtime': 123,
      'budget': 1000000,
      'revenue': 5000000,
      'vote_count': 321,
      'original_language': 'en',
      'genres': [
        {'id': 12, 'name': 'Adventure'},
        {'id': 878, 'name': 'Science Fiction'},
      ],
      'credits': {
        'cast': [
          {'name': 'Actor One', 'profile_path': '/actor.jpg'},
        ],
      },
      'videos': {
        'results': [
          {'key': 'ignored', 'site': 'Vimeo', 'type': 'Trailer'},
          {'key': 'youtube-key', 'site': 'YouTube', 'type': 'Trailer'},
        ],
      },
      'similar': {
        'page': 1,
        'total_pages': 1,
        'results': [
          {'id': 99, 'title': 'Similar Movie'},
        ],
      },
    });

    final movie = dto.toDomain();

    expect(movie.id, 42);
    expect(movie.title, 'Popcorn Test');
    expect(movie.voteAverage, 8.5);
    expect(movie.genres, ['Adventure', 'Science Fiction']);
    expect(movie.cast.single.name, 'Actor One');
    expect(movie.trailerKey, 'youtube-key');
    expect(movie.similar.single.id, 99);
  });

  test('normalizes missing TMDB values to safe defaults', () {
    final movie = TmdbMovieDto.fromJson(const <String, dynamic>{}).toDomain();

    expect(movie.id, 0);
    expect(movie.title, 'Untitled');
    expect(movie.overview, isEmpty);
    expect(movie.genreIds, isEmpty);
    expect(movie.genres, isEmpty);
    expect(movie.cast, isEmpty);
    expect(movie.similar, isEmpty);
  });
}
