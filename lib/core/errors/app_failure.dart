import 'package:dio/dio.dart';

sealed class AppFailure implements Exception {
  const AppFailure(this.message, {this.cause});

  final String message;
  final Object? cause;
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure({Object? cause})
      : super('Unable to connect to the movie service.', cause: cause);
}

final class TimeoutFailure extends AppFailure {
  const TimeoutFailure({Object? cause})
      : super('The request timed out. Please try again.', cause: cause);
}

final class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure({Object? cause})
      : super('The API token is missing or invalid.', cause: cause);
}

final class RateLimitFailure extends AppFailure {
  const RateLimitFailure({Object? cause})
      : super('Too many requests. Please wait and try again.', cause: cause);
}

final class ServerFailure extends AppFailure {
  const ServerFailure({Object? cause})
      : super('The movie service is temporarily unavailable.', cause: cause);
}

final class ParsingFailure extends AppFailure {
  const ParsingFailure({Object? cause})
      : super('The movie response could not be read.', cause: cause);
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure({Object? cause})
      : super('Something went wrong.', cause: cause);
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
