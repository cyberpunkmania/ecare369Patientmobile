import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../models/patient_profile_model.dart';

abstract class ProfileRemoteDataSource {
  Future<PatientProfileModel> getProfile(String patientId);

  Future<PatientProfileModel> updateDemographics({
    required String patientId,
    required Map<String, dynamic> body,
  });

  Future<PatientProfileModel> updateEmergencyContact({
    required String patientId,
    required Map<String, dynamic> body,
  });

  Future<PatientProfileModel> addInsurance({
    required String patientId,
    required Map<String, dynamic> body,
  });

  Future<PatientProfileModel> updateInsurance({
    required String patientId,
    required String insuranceId,
    required Map<String, dynamic> body,
  });

  Future<PatientProfileModel> removeInsurance({
    required String patientId,
    required String insuranceId,
  });
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final Dio _dio;

  ProfileRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  Map<String, dynamic> _unwrap(dynamic body) {
    if (body is Map<String, dynamic>) {
      final inner = body['data'];
      if (inner is Map<String, dynamic>) return inner;
      return body;
    }
    return <String, dynamic>{};
  }

  @override
  Future<PatientProfileModel> getProfile(String patientId) async {
    try {
      final res = await _dio.get(ApiEndpoints.patientById(patientId));
      return PatientProfileModel.fromJson(_unwrap(res.data));
    } on DioException catch (e) {
      throw _toException(e);
    }
  }

  @override
  Future<PatientProfileModel> updateDemographics({
    required String patientId,
    required Map<String, dynamic> body,
  }) async {
    try {
      await _dio.put(
        ApiEndpoints.patientDemographics(patientId),
        data: body,
      );
      return getProfile(patientId);
    } on DioException catch (e) {
      throw _toException(e);
    }
  }

  @override
  Future<PatientProfileModel> updateEmergencyContact({
    required String patientId,
    required Map<String, dynamic> body,
  }) async {
    try {
      await _dio.put(
        ApiEndpoints.patientEmergencyContact(patientId),
        data: body,
      );
      return getProfile(patientId);
    } on DioException catch (e) {
      throw _toException(e);
    }
  }

  @override
  Future<PatientProfileModel> addInsurance({
    required String patientId,
    required Map<String, dynamic> body,
  }) async {
    try {
      await _dio.post(ApiEndpoints.patientAddInsurance(patientId), data: body);
      return getProfile(patientId);
    } on DioException catch (e) {
      throw _toException(e);
    }
  }

  @override
  Future<PatientProfileModel> updateInsurance({
    required String patientId,
    required String insuranceId,
    required Map<String, dynamic> body,
  }) async {
    try {
      await _dio.put(
        ApiEndpoints.patientUpdateInsurance(patientId, insuranceId),
        data: body,
      );
      return getProfile(patientId);
    } on DioException catch (e) {
      throw _toException(e);
    }
  }

  @override
  Future<PatientProfileModel> removeInsurance({
    required String patientId,
    required String insuranceId,
  }) async {
    try {
      await _dio.delete(
        ApiEndpoints.patientRemoveInsurance(patientId, insuranceId),
      );
      return getProfile(patientId);
    } on DioException catch (e) {
      throw _toException(e);
    }
  }

  ServerException _toException(DioException e) {
    if (e.error is ServerException) return e.error as ServerException;
    final body = e.response?.data;
    final msg = body is Map ? body['message']?.toString() : null;
    return ServerException(
      message: msg ?? e.message ?? 'Unable to reach the profile service.',
      statusCode: e.response?.statusCode,
    );
  }
}
