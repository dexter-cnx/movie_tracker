import 'package:dio/dio.dart';

sealed class AppFailure implements Exception {
  const AppFailure(this.message, {this.cause});

  final String message;
  final Object? cause;
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure({super.cause})
      : super('Unable to connect to the movie service.');
}

final class TimeoutFailure extends AppFailure {
  const TimeoutFailure({super.cause})
      : super('The request timed out. Please try again.');
}

final class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure({super.cause})
      : super('The API token is missing or invalid.');
}

final class RateLimitFailure extends AppFailure {
  const RateLimitFailure({super.cause})
      : super('Too many requests. Please wait and try again.');
}

final class ServerFailure extends AppFailure {
  const ServerFailure({super.cause})
      : super('The movie service is temporarily unavailable.');
}

final class ParsingFailure extends AppFailure {
  const ParsingFailure({super.cause})
      : super('The movie response could not be read.');
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure({super.cause}) : super('Something went wrong.');
}

AppFailure mapExceptionToFailure(Object error) {
  if (error is AppFailure) return error;
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutFailure(cause: error);
      case DioExceptionType.connectionError:
        return NetworkFailure(cause: error);
      default:
        final status = error.response?.statusCode;
        if (status == 401 || status == 403) {
          return UnauthorizedFailure(cause: error);
        }
        if (status == 429) return RateLimitFailure(cause: error);
        if (status != null && status >= 500) {
          return ServerFailure(cause: error);
        }
        return UnknownFailure(cause: error);
    }
  }
  if (error is FormatException || error is TypeError) {
    return ParsingFailure(cause: error);
  }
  return UnknownFailure(cause: error);
}
