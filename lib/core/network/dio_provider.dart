import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:popcorn_movie_tracker/core/network/rate_limit_interceptor.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.themoviedb.org/3',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 12),
      headers: {
        'accept': 'application/json',
        if ((dotenv.env['TMDB_BEARER_TOKEN'] ?? '').isNotEmpty)
          'Authorization': 'Bearer ${dotenv.env['TMDB_BEARER_TOKEN']}',
      },
    ),
  );
  dio.interceptors.add(RateLimitInterceptor(dio));
  return dio;
});
