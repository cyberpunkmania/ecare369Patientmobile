import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../models/public_tenant_model.dart';

abstract class TenantRemoteDataSource {
  /// GET `/api/tenants/public` → unwraps the `ListResponse<PublicTenantDto>`
  /// envelope `{ data: [...], count }`.
  Future<List<PublicTenantModel>> getPublicTenants();
}

class TenantRemoteDataSourceImpl implements TenantRemoteDataSource {
  final Dio _dio;

  TenantRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<List<PublicTenantModel>> getPublicTenants() async {
    try {
      final response = await _dio.get(ApiEndpoints.tenantsPublic);
      final body = response.data;

      // Envelope: { data: [...], count: n }
      final raw = body is Map<String, dynamic>
          ? (body['data'] as List? ?? const [])
          : (body as List? ?? const []);

      return raw
          .whereType<Map<String, dynamic>>()
          .map(PublicTenantModel.fromJson)
          .toList(growable: false);
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data is Map<String, dynamic>
            ? ((e.response!.data as Map<String, dynamic>)['message']
                      as String? ??
                  e.message ??
                  'Failed to load tenants')
            : (e.message ?? 'Failed to load tenants'),
        statusCode: e.response?.statusCode,
      );
    }
  }
}
