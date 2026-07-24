import 'dart:async';
import 'package:dio/dio.dart';

class RateLimitInterceptor extends Interceptor {
  RateLimitInterceptor(this.dio, {this.maxRetries = 3});
  final Dio dio;
  final int maxRetries;

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 429) {
      return handler.next(err);
    }
    final request = err.requestOptions;
    final retryCount = (request.extra['retryCount'] as int?) ?? 0;
    if (retryCount >= maxRetries) return handler.next(err);

    final retryAfter =
        int.tryParse(err.response?.headers.value('retry-after') ?? '');
    final delay = Duration(seconds: retryAfter ?? (1 << retryCount));
    await Future<void>.delayed(delay);

    request.extra['retryCount'] = retryCount + 1;
    try {
      final response = await dio.fetch<dynamic>(request);
      return handler.resolve(response);
    } on DioException catch (retryError) {
      return handler.next(retryError);
    }
  }
}
