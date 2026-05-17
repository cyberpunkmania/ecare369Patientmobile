import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../models/appointment_model.dart';
import '../models/my_appointment_dto.dart';

abstract class AppointmentRemoteDataSource {
  Future<List<MyAppointmentDto>> getAppointments();
  Future<AppointmentModel> getAppointmentById(String id);
  Future<AppointmentModel> bookAppointment({
    required String doctorId,
    required DateTime date,
    required String timeSlot,
    String? type,
    String? reason,
  });
  Future<void> cancelAppointment(String id, {String reason = ''});
  Future<AppointmentModel> rescheduleAppointment({
    required String id,
    required DateTime newDate,
    required String newTimeSlot,
  });
}

class AppointmentRemoteDataSourceImpl implements AppointmentRemoteDataSource {
  final Dio _dio;

  AppointmentRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<List<MyAppointmentDto>> getAppointments() async {
    try {
      final response = await _dio.get(
        ApiEndpoints.myAppointments,
        queryParameters: {'activeOnly': true, 'page': 1, 'pageSize': 50},
      );
      final data = response.data;
      final List list = data is List
          ? data
          : (data as Map<String, dynamic>)['data'] as List? ?? [];
      return list
          .map((e) => MyAppointmentDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _extract(e);
    }
  }

  @override
  Future<AppointmentModel> getAppointmentById(String id) async {
    try {
      final response = await _dio.get(ApiEndpoints.appointmentById(id));
      return AppointmentModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _extract(e);
    }
  }

  @override
  Future<AppointmentModel> bookAppointment({
    required String doctorId,
    required DateTime date,
    required String timeSlot,
    String? type,
    String? reason,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.bookAppointment,
        data: {
          'doctorId': doctorId,
          'appointmentDate': date.toIso8601String(),
          'timeSlot': timeSlot,
          if (type != null) 'type': type,
          if (reason != null) 'reason': reason,
        },
      );
      return AppointmentModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _extract(e);
    }
  }

  @override
  Future<void> cancelAppointment(String id, {String reason = ''}) async {
    try {
      await _dio.post(
        ApiEndpoints.cancelAppointment(id),
        data: {'reason': reason},
      );
    } on DioException catch (e) {
      throw _extract(e);
    }
  }

  @override
  Future<AppointmentModel> rescheduleAppointment({
    required String id,
    required DateTime newDate,
    required String newTimeSlot,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.rescheduleAppointment(id),
        data: {
          'appointmentDate': newDate.toIso8601String(),
          'timeSlot': newTimeSlot,
        },
      );
      return AppointmentModel.fromJson(response.data as Map<String, dynamic>);
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
