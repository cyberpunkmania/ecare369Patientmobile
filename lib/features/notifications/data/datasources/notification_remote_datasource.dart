import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../models/notification_model.dart';

abstract class NotificationRemoteDataSource {
  Future<List<NotificationModel>> getNotifications();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final Dio _dio;

  NotificationRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await _dio.get(ApiEndpoints.notifications);
      final data = response.data;
      final List list = data is List
          ? data
          : (data as Map<String, dynamic>)['data'] as List? ?? [];
      return list
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _extract(e);
    }
  }

  @override
  Future<void> markAsRead(String id) async {
    try {
      await _dio.put(ApiEndpoints.markNotificationRead(id));
    } on DioException catch (e) {
      throw _extract(e);
    }
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      await _dio.put(ApiEndpoints.markAllNotificationsRead);
    } on DioException catch (e) {
      throw _extract(e);
    }
  }

  ServerException _extract(DioException e) {
    if (e.error is ServerException) return e.error as ServerException;
    return ServerException(
      message: e.message ?? 'Unknown error',
      statusCode: e.response?.statusCode,
    );
  }
}
