import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:popcorn_movie_tracker/core/errors/app_failure.dart';

void main() {
  test('maps Dio timeout to TimeoutFailure', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/movies'),
      type: DioExceptionType.receiveTimeout,
    );

    expect(mapExceptionToFailure(error), isA<TimeoutFailure>());
  });

  test('maps 401 to UnauthorizedFailure', () {
    final request = RequestOptions(path: '/movies');
    final error = DioException(
      requestOptions: request,
      response: Response<dynamic>(requestOptions: request, statusCode: 401),
    );

    expect(mapExceptionToFailure(error), isA<UnauthorizedFailure>());
  });

  test('maps 429 to RateLimitFailure', () {
    final request = RequestOptions(path: '/movies');
    final error = DioException(
      requestOptions: request,
      response: Response<dynamic>(requestOptions: request, statusCode: 429),
    );

    expect(mapExceptionToFailure(error), isA<RateLimitFailure>());
  });

  test('maps malformed payload errors to ParsingFailure', () {
    expect(
      mapExceptionToFailure(const FormatException('bad payload')),
      isA<ParsingFailure>(),
    );
  });
}
