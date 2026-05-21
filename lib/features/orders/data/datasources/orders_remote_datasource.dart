import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../models/service_request_model.dart';

abstract class OrdersRemoteDataSource {
  Future<List<ServiceRequestModel>> getOrdersByAppointment(
    String appointmentId,
  );
  Future<ServiceRequestModel> getOrderById(String orderId);
}

class OrdersRemoteDataSourceImpl implements OrdersRemoteDataSource {
  final Dio _dio;
  OrdersRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  List<ServiceRequestModel> _parseList(dynamic body) {
    List raw;
    if (body is List) {
      raw = body;
    } else if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is List) {
        raw = data;
      } else if (data is Map<String, dynamic> && data['items'] is List) {
        raw = data['items'] as List;
      } else if (body['items'] is List) {
        raw = body['items'] as List;
      } else {
        raw = const [];
      }
    } else {
      raw = const [];
    }
    return raw
        .whereType<Map<String, dynamic>>()
        .map(ServiceRequestModel.fromJson)
        .toList();
  }

  Map<String, dynamic> _unwrapObject(dynamic body) {
    if (body is Map<String, dynamic>) {
      final inner = body['data'];
      if (inner is Map<String, dynamic>) return inner;
      return body;
    }
    return <String, dynamic>{};
  }

  @override
  Future<List<ServiceRequestModel>> getOrdersByAppointment(
    String appointmentId,
  ) async {
    try {
      final res = await _dio.get(
        ApiEndpoints.ordersByAppointment(appointmentId),
      );
      return _parseList(res.data);
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        message: data is Map<String, dynamic>
            ? (data['message']?.toString() ?? 'Failed to load orders')
            : 'Failed to load orders',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<ServiceRequestModel> getOrderById(String orderId) async {
    try {
      final res = await _dio.get(ApiEndpoints.orderById(orderId));
      return ServiceRequestModel.fromJson(_unwrapObject(res.data));
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        message: data is Map<String, dynamic>
            ? (data['message']?.toString() ?? 'Failed to load order')
            : 'Failed to load order',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
