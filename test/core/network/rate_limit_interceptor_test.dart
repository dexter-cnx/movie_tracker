import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:popcorn_movie_tracker/core/network/rate_limit_interceptor.dart';

class MockDio extends Mock implements Dio {}

class MockErrorInterceptorHandler extends Mock
    implements ErrorInterceptorHandler {}

void main() {
  late MockDio dio;
  late MockErrorInterceptorHandler handler;

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: '/fallback'));
  });

  setUp(() {
    dio = MockDio();
    handler = MockErrorInterceptorHandler();
  });

  DioException errorWithStatus(int statusCode, {String? retryAfter}) {
    final request = RequestOptions(path: '/movie/popular');
    return DioException(
      requestOptions: request,
      response: Response<dynamic>(
        requestOptions: request,
        statusCode: statusCode,
        headers: Headers.fromMap({
          if (retryAfter != null) 'retry-after': [retryAfter],
        }),
      ),
      type: DioExceptionType.badResponse,
    );
  }

  test('passes non-429 errors through without retrying', () async {
    final interceptor = RateLimitInterceptor(dio);
    final error = errorWithStatus(500);

    await interceptor.onError(error, handler);

    verify(() => handler.next(error)).called(1);
    verifyNever(() => dio.fetch<dynamic>(any()));
  });

  test('retries 429 and resolves successful retry response', () async {
    final interceptor = RateLimitInterceptor(dio);
    final error = errorWithStatus(429, retryAfter: '0');
    final response = Response<dynamic>(
      requestOptions: error.requestOptions,
      statusCode: 200,
      data: {'ok': true},
    );
    when(() => dio.fetch<dynamic>(any())).thenAnswer((_) async => response);

    await interceptor.onError(error, handler);

    expect(error.requestOptions.extra['retryCount'], 1);
    verify(() => handler.resolve(response)).called(1);
  });

  test('stops retrying after maxRetries', () async {
    final interceptor = RateLimitInterceptor(dio, maxRetries: 1);
    final error = errorWithStatus(429, retryAfter: '0');
    error.requestOptions.extra['retryCount'] = 1;

    await interceptor.onError(error, handler);

    verify(() => handler.next(error)).called(1);
    verifyNever(() => dio.fetch<dynamic>(any()));
  });
}
