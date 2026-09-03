// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:popcorn_movie_tracker/features/movies/domain/entities/movie.dart';

part 'tmdb_dto.freezed.dart';
part 'tmdb_dto.g.dart';

@freezed
class TmdbMoviePageDto with _$TmdbMoviePageDto {
  const factory TmdbMoviePageDto({
    @Default(<TmdbMovieDto>[]) List<TmdbMovieDto> results,
    @Default(1) int page,
    @JsonKey(name: 'total_pages') @Default(1) int totalPages,
  }) = _TmdbMoviePageDto;

  factory TmdbMoviePageDto.fromJson(Map<String, dynamic> json) =>
      _$TmdbMoviePageDtoFromJson(json);
}

@freezed
class TmdbMovieDto with _$TmdbMovieDto {
  const TmdbMovieDto._();

  const factory TmdbMovieDto({
    @Default(0) int id,
    @Default('') String title,
    @Default('') String overview,
    @JsonKey(name: 'poster_path') String? posterPath,
    @JsonKey(name: 'backdrop_path') String? backdropPath,
    @JsonKey(name: 'release_date') @Default('') String releaseDate,
    @JsonKey(name: 'vote_average') @Default(0) double voteAverage,
    @JsonKey(name: 'genre_ids') @Default(<int>[]) List<int> genreIds,
    @Default(0) double popularity,
    int? runtime,
    int? budget,
    int? revenue,
    @JsonKey(name: 'vote_count') int? voteCount,
    @JsonKey(name: 'original_language') String? originalLanguage,
    @Default(<TmdbGenreDto>[]) List<TmdbGenreDto> genres,
    TmdbCreditsDto? credits,
    TmdbVideosDto? videos,
    TmdbMoviePageDto? similar,
  }) = _TmdbMovieDto;

  factory TmdbMovieDto.fromJson(Map<String, dynamic> json) =>
      _$TmdbMovieDtoFromJson(json);

  Movie toDomain() {
    final normalizedTitle = title.trim();
    final video = videos?.results.where((item) {
      return item.site == 'YouTube' &&
          (item.type == 'Trailer' || item.type == 'Teaser');
    }).firstOrNull;

    return Movie(
      id: id,
      title: normalizedTitle.isEmpty ? 'Untitled' : normalizedTitle,
      overview: overview,
      posterPath: posterPath,
      backdropPath: backdropPath,
      releaseDate: releaseDate,
      voteAverage: voteAverage,
      genreIds: genreIds,
      popularity: popularity,
      runtime: runtime,
      budget: budget,
      revenue: revenue,
      voteCount: voteCount,
      originalLanguage: originalLanguage,
      genres: genres
          .map((genre) => genre.name.trim())
          .where((name) => name.isNotEmpty)
          .toList(growable: false),
      cast: (credits?.cast ?? const <TmdbCastDto>[])
          .take(12)
          .map(
            (member) => CastMember(
              name: member.name,
              profilePath: member.profilePath,
            ),
          )
          .toList(growable: false),
      trailerKey: video?.key,
      similar: (similar?.results ?? const <TmdbMovieDto>[])
          .take(12)
          .map((movie) => movie.toDomain())
          .toList(growable: false),
    );
  }
}

@freezed
class TmdbCreditsDto with _$TmdbCreditsDto {
  const factory TmdbCreditsDto({
    @Default(<TmdbCastDto>[]) List<TmdbCastDto> cast,
  }) = _TmdbCreditsDto;

  factory TmdbCreditsDto.fromJson(Map<String, dynamic> json) =>
      _$TmdbCreditsDtoFromJson(json);
}

@freezed
class TmdbCastDto with _$TmdbCastDto {
  const factory TmdbCastDto({
    @Default('') String name,
    @JsonKey(name: 'profile_path') String? profilePath,
  }) = _TmdbCastDto;

  factory TmdbCastDto.fromJson(Map<String, dynamic> json) =>
      _$TmdbCastDtoFromJson(json);
}

@freezed
class TmdbVideosDto with _$TmdbVideosDto {
  const factory TmdbVideosDto({
    @Default(<TmdbVideoDto>[]) List<TmdbVideoDto> results,
  }) = _TmdbVideosDto;

  factory TmdbVideosDto.fromJson(Map<String, dynamic> json) =>
      _$TmdbVideosDtoFromJson(json);
}

@freezed
class TmdbVideoDto with _$TmdbVideoDto {
  const factory TmdbVideoDto({
    @Default('') String key,
    @Default('') String site,
    @Default('') String type,
  }) = _TmdbVideoDto;

  factory TmdbVideoDto.fromJson(Map<String, dynamic> json) =>
      _$TmdbVideoDtoFromJson(json);
}

@freezed
class TmdbGenreDto with _$TmdbGenreDto {
  const factory TmdbGenreDto({
    @Default(0) int id,
    @Default('') String name,
  }) = _TmdbGenreDto;

  factory TmdbGenreDto.fromJson(Map<String, dynamic> json) =>
      _$TmdbGenreDtoFromJson(json);
}

@freezed
class TmdbGenreListDto with _$TmdbGenreListDto {
  const factory TmdbGenreListDto({
    @Default(<TmdbGenreDto>[]) List<TmdbGenreDto> genres,
  }) = _TmdbGenreListDto;

  factory TmdbGenreListDto.fromJson(Map<String, dynamic> json) =>
      _$TmdbGenreListDtoFromJson(json);
}

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
