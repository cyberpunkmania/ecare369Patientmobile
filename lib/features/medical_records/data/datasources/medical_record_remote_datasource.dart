import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/storage/secure_storage.dart';
import '../models/medical_record_model.dart';

abstract class MedicalRecordRemoteDataSource {
  Future<List<MedicalRecordModel>> getMedicalRecords();
  Future<MedicalRecordModel> getMedicalRecordById(String id);
}

class MedicalRecordRemoteDataSourceImpl
    implements MedicalRecordRemoteDataSource {
  final Dio _dio;
  final SecureStorage _secureStorage;

  MedicalRecordRemoteDataSourceImpl({
    required Dio dio,
    required SecureStorage secureStorage,
  }) : _dio = dio,
       _secureStorage = secureStorage;

  Future<String> _patientId() async {
    final id = await _secureStorage.getPatientId();
    if (id == null || id.isEmpty) {
      throw const ServerException(
        message: 'Sign in as a patient to view clinical history.',
      );
    }
    return id;
  }

  @override
  Future<List<MedicalRecordModel>> getMedicalRecords() async {
    try {
      final patientId = await _patientId();
      final response = await _dio.get(
        ApiEndpoints.patientClinicalHistory(patientId),
      );
      final body = response.data;
      final Map<String, dynamic> payload = body is Map<String, dynamic>
          ? (body['data'] as Map<String, dynamic>? ?? body)
          : <String, dynamic>{};
      final consultations = payload['consultations'];
      if (consultations is! List) return <MedicalRecordModel>[];
      return consultations.whereType<Map<String, dynamic>>().map((c) {
        final id = (c['_id'] ?? c['id'] ?? '').toString();
        final dateRaw = (c['date'] ?? c['consultationDate'] ?? c['createdAt'])
            ?.toString();
        final doctor =
            c['doctorName']?.toString() ??
            c['doctor']?.toString() ??
            c['attendingDoctor']?.toString();
        final reason =
            c['chiefComplaint']?.toString() ??
            c['reason']?.toString() ??
            c['diagnosis']?.toString();
        final title =
            (c['title'] as String?) ??
            (reason != null && reason.isNotEmpty ? reason : 'Consultation');
        return MedicalRecordModel(
          id: id,
          title: title,
          type: c['type']?.toString() ?? 'visit_summary',
          description: c['notes']?.toString() ?? reason,
          doctorName: doctor,
          date: DateTime.tryParse(dateRaw ?? '') ?? DateTime.now(),
          details: c,
          fileUrl: c['fileUrl']?.toString(),
        );
      }).toList();
    } on DioException catch (e) {
      throw _extract(e);
    }
  }

  @override
  Future<MedicalRecordModel> getMedicalRecordById(String id) async {
    final all = await getMedicalRecords();
    final match = all.where((r) => r.id == id);
    if (match.isEmpty) {
      throw const ServerException(
        message: 'Clinical history entry not found.',
        statusCode: 404,
      );
    }
    return match.first as MedicalRecordModel;
  }

  ServerException _extract(DioException e) {
    if (e.error is ServerException) return e.error as ServerException;
    final body = e.response?.data;
    final msg = body is Map ? body['message']?.toString() : null;
    return ServerException(
      message: msg ?? e.message ?? 'Unable to load clinical history.',
      statusCode: e.response?.statusCode,
    );
  }
}
