import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:popcorn_movie_tracker/core/network/dio_provider.dart';
import 'package:popcorn_movie_tracker/features/movies/data/movie_cache_local_data_source.dart';
import 'package:popcorn_movie_tracker/features/movies/data/movie_repository_impl.dart';
import 'package:popcorn_movie_tracker/features/movies/data/tmdb_remote_data_source.dart';
import 'package:popcorn_movie_tracker/features/movies/domain/entities/movie.dart';
import 'package:popcorn_movie_tracker/features/movies/domain/entities/movie_load_result.dart';
import 'package:popcorn_movie_tracker/features/movies/domain/repositories/movie_repository.dart';

final movieCacheDataSourceProvider = Provider<MovieCacheLocalDataSource>(
  (ref) => MovieCacheLocalDataSource(
    Hive.box<Map>(MovieCacheLocalDataSource.boxName),
  ),
);

final movieRepositoryProvider = Provider<MovieRepository>(
  (ref) => MovieRepositoryImpl(
    TmdbRemoteDataSource(ref.watch(dioProvider)),
    cache: ref.watch(movieCacheDataSourceProvider),
  ),
);

String apiLanguage(String localeCode) => localeCode == 'th' ? 'th-TH' : 'en-US';

final trendingFeedProvider = FutureProvider.family<MovieLoadResult, String>(
  (ref, lang) => ref.watch(movieRepositoryProvider).getTrendingFeed(lang),
);

final trendingProvider = FutureProvider.family<List<Movie>, String>(
  (ref, lang) async => (await ref.watch(trendingFeedProvider(lang).future)).movies,
);

final movieDetailProvider = FutureProvider.family<Movie, MovieDetailArg>(
  (ref, arg) =>
      ref.watch(movieRepositoryProvider).getDetails(arg.id, arg.language),
);

final genresProvider = FutureProvider.family<List<Genre>, String>(
  (ref, lang) => ref.watch(movieRepositoryProvider).getGenres(lang),
);

class MovieDetailArg {
  const MovieDetailArg(this.id, this.language);

  final int id;
  final String language;

  @override
  bool operator ==(Object other) =>
      other is MovieDetailArg && other.id == id && other.language == language;

  @override
  int get hashCode => Object.hash(id, language);
}
