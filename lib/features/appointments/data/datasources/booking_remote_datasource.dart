import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../models/confirm_booking_request.dart';
import '../models/doctor_availability_dto.dart';
import '../models/doctor_available_slots_dto.dart';
import '../models/mpesa_initiate_result.dart';
import '../models/patient_profile_dto.dart';
import '../models/slot_hold_dto.dart';

abstract class BookingRemoteDataSource {
  Future<PatientProfileDto> getPatientProfile(String patientId);

  /// Lists all active doctors in the patient's tenant (auto-scoped via JWT).
  /// Mirrors the web frontend's call to `/api/doctors?status=Active`.
  Future<List<DoctorAvailabilityDto>> getActiveDoctors({String? specialty});

  /// Resolves the schedule (`scheduleId`) for a doctor at a specific branch.
  Future<String> resolveScheduleId({
    required String doctorId,
    required String branchId,
  });

  Future<List<DoctorAvailabilityDto>> getAvailableDoctors({
    required String branchId,
    required String date,
    String? specialty,
    bool onlineOnly = true,
  });

  Future<List<DoctorAvailableSlotsDto>> getSlotRange({
    required String scheduleId,
    required String from,
    required String to,
    bool onlineOnly = true,
  });

  Future<DoctorAvailableSlotsDto> getSlotsForDate({
    required String scheduleId,
    required String date,
    bool onlineOnly = false,
  });

  Future<SlotHoldDto> holdSlot({
    required String scheduleId,
    required String slotId,
    required String patientId,
    String? slotDate,
    int? holdDurationMinutes,
  });

  Future<void> releaseSlot({
    required String scheduleId,
    required String slotId,
    required String patientId,
  });

  Future<String> confirmBooking(ConfirmBookingRequest request);

  /// Initiates an M-Pesa STK push to the supplied phone number for the given
  /// branch and amount. Returns the resulting `paymentId` and metadata.
  Future<MpesaInitiateResult> initiateMpesaStk({
    required String branchId,
    required String phoneNumber,
    required double amount,
    String? slotId,
    String? patientId,
  });
}

class BookingRemoteDataSourceImpl implements BookingRemoteDataSource {
  final Dio _dio;

  BookingRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  /// Unwraps the standard API envelope `{message, data, timestamp}`.
  Map<String, dynamic> _unwrapData(dynamic responseData) {
    if (responseData is Map<String, dynamic> &&
        responseData.containsKey('data') &&
        responseData['data'] is Map<String, dynamic>) {
      return responseData['data'] as Map<String, dynamic>;
    }
    if (responseData is Map<String, dynamic>) return responseData;
    return {};
  }

  /// Unwraps the API envelope when `data` is a list.
  List<dynamic> _unwrapList(dynamic responseData) {
    if (responseData is Map<String, dynamic> &&
        responseData.containsKey('data') &&
        responseData['data'] is List) {
      return responseData['data'] as List<dynamic>;
    }
    if (responseData is List) return responseData;
    return [];
  }

  @override
  Future<PatientProfileDto> getPatientProfile(String patientId) async {
    try {
      final response = await _dio.get(ApiEndpoints.patientProfile(patientId));
      return PatientProfileDto.fromJson(_unwrapData(response.data));
    } on DioException catch (e) {
      throw _extract(e);
    }
  }

  @override
  Future<List<DoctorAvailabilityDto>> getActiveDoctors({
    String? specialty,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.activeDoctorsList,
        queryParameters: {
          'status': 'Active',
          'pageSize': 50,
          if (specialty != null && specialty.isNotEmpty) 'specialty': specialty,
        },
      );

      // Envelope: { message, data: { data: [...], pageNumber, ... }, timestamp }
      final paged = _unwrapData(response.data);
      final List<dynamic> items = paged['data'] is List
          ? paged['data'] as List<dynamic>
          : _unwrapList(response.data);

      return items
          .whereType<Map<String, dynamic>>()
          // Only show approved (KYC-verified) doctors to patients.
          .where((j) {
            final kyc = (j['kycStatus'] as String?)?.toLowerCase();
            // Allow when kyc is missing (older records) or explicitly approved.
            return kyc == null || kyc.isEmpty || kyc == 'approved';
          })
          .map(DoctorAvailabilityDto.fromDoctorListing)
          .toList();
    } on DioException catch (e) {
      throw _extract(e);
    }
  }

  @override
  Future<String> resolveScheduleId({
    required String doctorId,
    required String branchId,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.scheduleByDoctorBranch(doctorId, branchId),
      );
      final data = _unwrapData(response.data);
      final id = (data['scheduleId'] ?? data['id']) as String?;
      if (id == null || id.isEmpty) {
        throw const ServerException(
          message:
              'This doctor has no published schedule yet. Please try another doctor.',
        );
      }
      return id;
    } on DioException catch (e) {
      throw _extract(e);
    }
  }

  @override
  Future<List<DoctorAvailabilityDto>> getAvailableDoctors({
    required String branchId,
    required String date,
    String? specialty,
    bool onlineOnly = true,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.availableDoctors(branchId),
        queryParameters: {
          'date': date,
          if (specialty != null && specialty.isNotEmpty) 'specialty': specialty,
          'onlineOnly': onlineOnly,
        },
      );
      return _unwrapList(response.data)
          .map((e) => DoctorAvailabilityDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _extract(e);
    }
  }

  @override
  Future<List<DoctorAvailableSlotsDto>> getSlotRange({
    required String scheduleId,
    required String from,
    required String to,
    bool onlineOnly = true,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.slotRange(scheduleId),
        queryParameters: {'from': from, 'to': to, 'onlineOnly': onlineOnly},
      );
      return _unwrapList(response.data)
          .map(
            (e) => DoctorAvailableSlotsDto.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (e) {
      throw _extract(e);
    }
  }

  @override
  Future<DoctorAvailableSlotsDto> getSlotsForDate({
    required String scheduleId,
    required String date,
    bool onlineOnly = false,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.slotsForDate(scheduleId),
        queryParameters: {'date': date, 'onlineOnly': onlineOnly},
      );
      return DoctorAvailableSlotsDto.fromJson(_unwrapData(response.data));
    } on DioException catch (e) {
      throw _extract(e);
    }
  }

  @override
  Future<SlotHoldDto> holdSlot({
    required String scheduleId,
    required String slotId,
    required String patientId,
    String? slotDate,
    int? holdDurationMinutes,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.holdSlot(scheduleId, slotId),
        data: {
          'patientId': patientId,
          if (slotDate != null) 'slotDate': slotDate,
          if (holdDurationMinutes != null)
            'holdDurationMinutes': holdDurationMinutes,
        },
      );
      return SlotHoldDto.fromJson(_unwrapData(response.data));
    } on DioException catch (e) {
      throw _extract(e);
    }
  }

  @override
  Future<void> releaseSlot({
    required String scheduleId,
    required String slotId,
    required String patientId,
  }) async {
    try {
      await _dio.delete(
        ApiEndpoints.releaseSlot(scheduleId, slotId),
        queryParameters: {'patientId': patientId},
      );
    } on DioException catch (e) {
      throw _extract(e);
    }
  }

  @override
  Future<String> confirmBooking(ConfirmBookingRequest request) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.createAppointment,
        data: request.toJson(),
      );
      final data = _unwrapData(response.data);
      // API returns the appointment ID as a string in data, or the full
      // envelope may just have a string `data` field.
      if (response.data is Map<String, dynamic> &&
          response.data['data'] is String) {
        return response.data['data'] as String;
      }
      return data['id'] as String? ?? '';
    } on DioException catch (e) {
      throw _extract(e);
    }
  }

  @override
  Future<MpesaInitiateResult> initiateMpesaStk({
    required String branchId,
    required String phoneNumber,
    required double amount,
    String? slotId,
    String? patientId,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.paymentInitiate,
        data: {
          'branchId': branchId,
          'phoneNumber': phoneNumber,
          'amount': amount,
          'preferredMethod': 'Mpesa',
          if (slotId != null) 'slotId': slotId,
          if (patientId != null) 'patientId': patientId,
        },
      );
      return MpesaInitiateResult.fromJson(_unwrapData(response.data));
    } on DioException catch (e) {
      throw _extract(e);
    }
  }

  ServerException _extract(DioException e) {
    if (e.error is ServerException) return e.error as ServerException;
    final msg = (e.response?.data is Map)
        ? (e.response!.data as Map)['message']?.toString()
        : null;
    return ServerException(
      message: msg ?? e.message ?? 'Unknown error',
      statusCode: e.response?.statusCode,
    );
  }
}
