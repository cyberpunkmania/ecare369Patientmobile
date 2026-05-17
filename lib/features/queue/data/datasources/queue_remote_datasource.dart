import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../models/queue_models.dart';

abstract class QueueRemoteDataSource {
  Future<QueueLiveSnapshotModel> getLiveSnapshot(String branchId);
  Future<QueuePositionModel?> getMyPosition({
    required String branchId,
    required String patientId,
    DateTime? date,
  });
}

class QueueRemoteDataSourceImpl implements QueueRemoteDataSource {
  final Dio _dio;
  QueueRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  Map<String, dynamic> _unwrap(dynamic body) {
    if (body is Map<String, dynamic>) {
      final inner = body['data'];
      if (inner is Map<String, dynamic>) return inner;
      return body;
    }
    return <String, dynamic>{};
  }

  @override
  Future<QueueLiveSnapshotModel> getLiveSnapshot(String branchId) async {
    try {
      final res = await _dio.get(ApiEndpoints.queueLiveByBranch(branchId));
      return QueueLiveSnapshotModel.fromJson(_unwrap(res.data), branchId);
    } on DioException catch (e) {
      throw _toException(e);
    }
  }

  @override
  Future<QueuePositionModel?> getMyPosition({
    required String branchId,
    required String patientId,
    DateTime? date,
  }) async {
    try {
      final res = await _dio.get(
        ApiEndpoints.queueMyPosition(branchId),
        queryParameters: {
          'patientId': patientId,
          if (date != null)
            'date':
                '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        },
      );
      final unwrapped = _unwrap(res.data);
      if (unwrapped.isEmpty) return null;
      return QueuePositionModel.fromJson(unwrapped);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _toException(e);
    }
  }

  ServerException _toException(DioException e) {
    if (e.error is ServerException) return e.error as ServerException;
    final body = e.response?.data;
    final msg = body is Map ? body['message']?.toString() : null;
    return ServerException(
      message: msg ?? e.message ?? 'Unable to reach the queue service.',
      statusCode: e.response?.statusCode,
    );
  }
}
