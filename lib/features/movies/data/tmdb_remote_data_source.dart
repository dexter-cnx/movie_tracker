import 'package:dio/dio.dart';
import 'package:popcorn_movie_tracker/features/movies/data/models/movie_model.dart';
import 'package:popcorn_movie_tracker/features/movies/domain/entities/movie.dart';
import 'package:popcorn_movie_tracker/features/movies/domain/entities/paged_movies.dart';
import 'package:popcorn_movie_tracker/features/movies/domain/repositories/movie_repository.dart';

class TmdbRemoteDataSource {
  TmdbRemoteDataSource(this.dio);
  final Dio dio;

  Map<String, dynamic> _params(String language) => {
        'language': language,
        'include_image_language': 'th,en,null',
        'include_video_language': 'th,en',
      };

  Future<List<Movie>> _list(
    String path,
    String language, [
    Map<String, dynamic>? extra,
  ]) async {
    final response = await dio.get<Map<String, dynamic>>(
      path,
      queryParameters: {..._params(language), ...?extra},
    );
    final results = response.data?['results'] as List? ?? const [];
    return results
        .whereType<Map<String, dynamic>>()
        .map(MovieModel.fromJson)
        .toList();
  }

  Future<List<Movie>> popular(String language) =>
      _list('/movie/popular', language, {'page': 1});
  Future<List<Movie>> trending(String language) =>
      _list('/trending/movie/week', language);
  Future<List<Movie>> topRated(String language) =>
      _list('/movie/top_rated', language);
  Future<List<Movie>> upcoming(String language) =>
      _list('/movie/upcoming', language);
  Future<List<Movie>> nowPlaying(String language) =>
      _list('/movie/now_playing', language);

  Future<Movie> details(int id, String language) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/movie/$id',
      queryParameters: {
        ..._params(language),
        'append_to_response': 'credits,videos,similar',
      },
    );
    return MovieModel.fromJson(response.data ?? const {});
  }

  Future<List<Movie>> search(String query, String language) =>
      _list('/search/movie', language, {'query': query, 'page': 1});

  Future<PagedMovies> searchPage(
    String query,
    String language,
    int page,
  ) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/search/movie',
      queryParameters: {
        ..._params(language),
        'query': query,
        'page': page,
      },
    );
    final data = response.data ?? const <String, dynamic>{};
    final results = data['results'] as List? ?? const [];
    return PagedMovies(
      items: results
          .whereType<Map<String, dynamic>>()
          .map(MovieModel.fromJson)
          .toList(growable: false),
      page: (data['page'] as num?)?.toInt() ?? page,
      totalPages: (data['total_pages'] as num?)?.toInt() ?? page,
    );
  }

  Future<List<Genre>> genres(String language) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/genre/movie/list',
      queryParameters: _params(language),
    );
    final list = response.data?['genres'] as List? ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => Genre((e['id'] as num).toInt(), e['name'] as String? ?? ''))
        .toList();
  }

  Future<List<Movie>> discover(int? genreId, String language) =>
      _list('/discover/movie', language, {
        if (genreId != null) 'with_genres': genreId,
        'sort_by': 'popularity.desc',
      });
}
