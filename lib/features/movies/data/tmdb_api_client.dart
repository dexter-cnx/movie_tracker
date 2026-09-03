import 'package:dio/dio.dart';
import 'package:popcorn_movie_tracker/features/movies/data/models/tmdb_dto.dart';
import 'package:retrofit/retrofit.dart';

part 'tmdb_api_client.g.dart';

@RestApi()
abstract class TmdbApiClient {
  factory TmdbApiClient(Dio dio, {String? baseUrl}) = _TmdbApiClient;

  @GET('/movie/popular')
  Future<TmdbMoviePageDto> popular(
    @Query('language') String language,
    @Query('include_image_language') String imageLanguages,
    @Query('include_video_language') String videoLanguages,
    @Query('page') int page,
  );

  @GET('/trending/movie/week')
  Future<TmdbMoviePageDto> trending(
    @Query('language') String language,
    @Query('include_image_language') String imageLanguages,
    @Query('include_video_language') String videoLanguages,
  );

  @GET('/movie/top_rated')
  Future<TmdbMoviePageDto> topRated(
    @Query('language') String language,
    @Query('include_image_language') String imageLanguages,
    @Query('include_video_language') String videoLanguages,
  );

  @GET('/movie/upcoming')
  Future<TmdbMoviePageDto> upcoming(
    @Query('language') String language,
    @Query('include_image_language') String imageLanguages,
    @Query('include_video_language') String videoLanguages,
  );

  @GET('/movie/now_playing')
  Future<TmdbMoviePageDto> nowPlaying(
    @Query('language') String language,
    @Query('include_image_language') String imageLanguages,
    @Query('include_video_language') String videoLanguages,
  );

  @GET('/movie/{id}')
  Future<TmdbMovieDto> details(
    @Path('id') int id,
    @Query('language') String language,
    @Query('include_image_language') String imageLanguages,
    @Query('include_video_language') String videoLanguages,
    @Query('append_to_response') String appendToResponse,
  );

  @GET('/search/movie')
  Future<TmdbMoviePageDto> search(
    @Query('query') String query,
    @Query('language') String language,
    @Query('include_image_language') String imageLanguages,
    @Query('include_video_language') String videoLanguages,
    @Query('page') int page,
  );

  @GET('/genre/movie/list')
  Future<TmdbGenreListDto> genres(
    @Query('language') String language,
  );

  @GET('/discover/movie')
  Future<TmdbMoviePageDto> discover(
    @Query('language') String language,
    @Query('include_image_language') String imageLanguages,
    @Query('include_video_language') String videoLanguages,
    @Query('with_genres') int? genreId,
    @Query('sort_by') String sortBy,
  );
}
