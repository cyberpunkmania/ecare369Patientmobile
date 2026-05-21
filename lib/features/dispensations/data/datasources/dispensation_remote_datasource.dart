import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../models/dispensation_model.dart';

abstract class DispensationRemoteDataSource {
  Future<List<DispensationModel>> getDispensations({
    required String patientId,
    int page = 1,
    int pageSize = 50,
  });
}

class DispensationRemoteDataSourceImpl implements DispensationRemoteDataSource {
  final Dio _dio;
  DispensationRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<List<DispensationModel>> getDispensations({
    required String patientId,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final res = await _dio.get(
        ApiEndpoints.pharmacyDispensationsMy,
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      final body = res.data;
      List list;
      if (body is List) {
        list = body;
      } else if (body is Map<String, dynamic>) {
        final inner = body['data'];
        if (inner is List) {
          list = inner;
        } else if (inner is Map<String, dynamic> && inner['items'] is List) {
          list = inner['items'] as List;
        } else if (body['items'] is List) {
          list = body['items'] as List;
        } else {
          list = const [];
        }
      } else {
        list = const [];
      }
      return list
          .whereType<Map<String, dynamic>>()
          .map(DispensationModel.fromJson)
          .toList();
    } on DioException catch (e) {
      if (e.error is ServerException) throw e.error as ServerException;
      final b = e.response?.data;
      final msg = b is Map ? b['message']?.toString() : null;
      throw ServerException(
        message: msg ?? e.message ?? 'Unable to load dispensations.',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
