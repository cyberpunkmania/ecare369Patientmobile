import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../models/bill_model.dart';

abstract class BillRemoteDataSource {
  Future<List<BillModel>> getBills({
    required String patientId,
    int page = 1,
    int pageSize = 50,
  });
  Future<BillModel> getBillById(String id);
  Future<Uint8List> downloadBillPdf(String billId);
}

class BillRemoteDataSourceImpl implements BillRemoteDataSource {
  final Dio _dio;
  BillRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  Map<String, dynamic> _unwrapObject(dynamic body) {
    if (body is Map<String, dynamic>) {
      final inner = body['data'];
      if (inner is Map<String, dynamic>) return inner;
      return body;
    }
    return <String, dynamic>{};
  }

  @override
  Future<List<BillModel>> getBills({
    required String patientId,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final res = await _dio.get(
        ApiEndpoints.billsMy,
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
          .map(BillModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw _toException(e);
    }
  }

  @override
  Future<BillModel> getBillById(String id) async {
    try {
      final res = await _dio.get(ApiEndpoints.billById(id));
      return BillModel.fromJson(_unwrapObject(res.data));
    } on DioException catch (e) {
      throw _toException(e);
    }
  }

  @override
  Future<Uint8List> downloadBillPdf(String billId) async {
    try {
      final res = await _dio.get<Uint8List>(
        ApiEndpoints.billPdfMy(billId),
        options: Options(responseType: ResponseType.bytes),
      );
      return res.data!;
    } on DioException catch (e) {
      throw _toException(e);
    }
  }

  ServerException _toException(DioException e) {
    if (e.error is ServerException) return e.error as ServerException;
    final b = e.response?.data;
    final msg = b is Map ? b['message']?.toString() : null;
    return ServerException(
      message: msg ?? e.message ?? 'Unable to load bills.',
      statusCode: e.response?.statusCode,
    );
  }
}
