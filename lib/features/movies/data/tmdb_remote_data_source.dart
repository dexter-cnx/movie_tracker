import 'package:dio/dio.dart';
import 'package:popcorn_movie_tracker/features/movies/data/tmdb_api_client.dart';
import 'package:popcorn_movie_tracker/features/movies/domain/entities/movie.dart';
import 'package:popcorn_movie_tracker/features/movies/domain/entities/paged_movies.dart';
import 'package:popcorn_movie_tracker/features/movies/domain/repositories/movie_repository.dart';

class TmdbRemoteDataSource {
  TmdbRemoteDataSource(Dio dio) : api = TmdbApiClient(dio);

  TmdbRemoteDataSource.withClient(this.api);

  static const _imageLanguages = 'th,en,null';
  static const _videoLanguages = 'th,en';
  static const _detailAppend = 'credits,videos,similar';

  final TmdbApiClient api;

  Future<List<Movie>> popular(String language) async {
    final page = await api.popular(
      language,
      _imageLanguages,
      _videoLanguages,
      1,
    );
    return _movies(page.results);
  }

  Future<List<Movie>> trending(String language) async {
    final page = await api.trending(
      language,
      _imageLanguages,
      _videoLanguages,
    );
    return _movies(page.results);
  }

  Future<List<Movie>> topRated(String language) async {
    final page = await api.topRated(
      language,
      _imageLanguages,
      _videoLanguages,
    );
    return _movies(page.results);
  }

  Future<List<Movie>> upcoming(String language) async {
    final page = await api.upcoming(
      language,
      _imageLanguages,
      _videoLanguages,
    );
    return _movies(page.results);
  }

  Future<List<Movie>> nowPlaying(String language) async {
    final page = await api.nowPlaying(
      language,
      _imageLanguages,
      _videoLanguages,
    );
    return _movies(page.results);
  }

  Future<Movie> details(int id, String language) async {
    final movie = await api.details(
      id,
      language,
      _imageLanguages,
      _videoLanguages,
      _detailAppend,
    );
    return movie.toDomain();
  }

  Future<List<Movie>> search(String query, String language) async {
    final page = await api.search(
      query,
      language,
      _imageLanguages,
      _videoLanguages,
      1,
    );
    return _movies(page.results);
  }

  Future<PagedMovies> searchPage(
    String query,
    String language,
    int page,
  ) async {
    final response = await api.search(
      query,
      language,
      _imageLanguages,
      _videoLanguages,
      page,
    );

    return PagedMovies(
      items: _movies(response.results),
      page: response.page,
      totalPages: response.totalPages,
    );
  }

  Future<List<Genre>> genres(String language) async {
    final response = await api.genres(language);
    return response.genres
        .map((genre) => Genre(genre.id, genre.name))
        .toList(growable: false);
  }

  Future<List<Movie>> discover(int? genreId, String language) async {
    final page = await api.discover(
      language,
      _imageLanguages,
      _videoLanguages,
      genreId,
      'popularity.desc',
    );
    return _movies(page.results);
  }

  List<Movie> _movies(Iterable<dynamic> dtos) => dtos
      .map((dto) => dto.toDomain() as Movie)
      .toList(growable: false);
}
