import 'package:dio/dio.dart';

import '../storage/secure_storage.dart';

/// Injects Bearer token, X-User-Role, and X-Tenant-ID on every request.
class AuthInterceptor extends Interceptor {
  final SecureStorage _secureStorage;

  AuthInterceptor({required SecureStorage secureStorage})
    : _secureStorage = secureStorage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _secureStorage.getAuthToken();
    final tenantId = await _secureStorage.getTenantId();

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // Patient role – always the same for this app.
    options.headers['X-User-Role'] = 'patient';

    if (tenantId != null && tenantId.isNotEmpty) {
      options.headers['X-Tenant-ID'] = tenantId;
    }

    handler.next(options);
  }
}
