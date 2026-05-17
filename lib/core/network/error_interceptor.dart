import 'package:dio/dio.dart';

import '../error/exceptions.dart';

/// Maps [DioException] to application-level [ServerException].
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final String message;
    final int? statusCode = err.response?.statusCode;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Connection timed out. Please try again.';
        break;
      case DioExceptionType.connectionError:
        message = 'No internet connection.';
        break;
      case DioExceptionType.badResponse:
        message =
            _extractMessage(err.response) ??
            'Server error (${statusCode ?? 'unknown'})';
        break;
      case DioExceptionType.cancel:
        message = 'Request cancelled.';
        break;
      default:
        message = 'An unexpected error occurred.';
    }

    // Wrap in our domain-level exception so the data layer can catch it.
    final serverException = ServerException(
      message: message,
      statusCode: statusCode,
    );

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: serverException,
      ),
    );
  }

  String? _extractMessage(Response? response) {
    if (response?.data == null) return null;
    if (response!.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      return data['message'] as String? ??
          data['error'] as String? ??
          data['detail'] as String?;
    }
    return response.data.toString();
  }
}
