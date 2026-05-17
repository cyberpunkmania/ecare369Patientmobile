import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../config/env_config.dart';
import 'auth_interceptor.dart';
import 'error_interceptor.dart';

/// Factory that builds a configured [Dio] instance.
class ApiClient {
  final AuthInterceptor _authInterceptor;
  final ErrorInterceptor _errorInterceptor;

  ApiClient({
    required AuthInterceptor authInterceptor,
    required ErrorInterceptor errorInterceptor,
  }) : _authInterceptor = authInterceptor,
       _errorInterceptor = errorInterceptor;

  Dio get dio {
    final dio = Dio(
      BaseOptions(
        baseUrl: EnvConfig.baseUrl,
        connectTimeout: const Duration(milliseconds: EnvConfig.connectTimeout),
        receiveTimeout: const Duration(milliseconds: EnvConfig.receiveTimeout),
        sendTimeout: const Duration(milliseconds: EnvConfig.sendTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.addAll([
      _authInterceptor,
      _errorInterceptor,
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        compact: true,
      ),
    ]);

    return dio;
  }
}
