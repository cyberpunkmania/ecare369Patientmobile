import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../data/datasources/booking_remote_datasource.dart';
import '../../data/models/confirm_booking_request.dart';
import '../../data/models/doctor_availability_dto.dart';
import '../../data/models/doctor_available_slots_dto.dart';
import '../../data/models/mpesa_initiate_result.dart';
import '../../data/models/patient_profile_dto.dart';
import '../../data/models/slot_hold_dto.dart';
import '../../domain/repositories/booking_repository.dart';

class BookingRepositoryImpl implements BookingRepository {
  final BookingRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  BookingRepositoryImpl({
    required BookingRemoteDataSource remoteDataSource,
    required NetworkInfo networkInfo,
  }) : _remoteDataSource = remoteDataSource,
       _networkInfo = networkInfo;

  @override
  Future<Either<Failure, PatientProfileDto>> getPatientProfile(
    String patientId,
  ) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final profile = await _remoteDataSource.getPatientProfile(patientId);
      return Right(profile);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, List<DoctorAvailabilityDto>>> getActiveDoctors({
    String? specialty,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final doctors = await _remoteDataSource.getActiveDoctors(
        specialty: specialty,
      );
      return Right(doctors);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, String>> resolveScheduleId({
    required String doctorId,
    required String branchId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final id = await _remoteDataSource.resolveScheduleId(
        doctorId: doctorId,
        branchId: branchId,
      );
      return Right(id);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, List<DoctorAvailabilityDto>>> getAvailableDoctors({
    required String branchId,
    required String date,
    String? specialty,
    bool onlineOnly = true,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final doctors = await _remoteDataSource.getAvailableDoctors(
        branchId: branchId,
        date: date,
        specialty: specialty,
        onlineOnly: onlineOnly,
      );
      return Right(doctors);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, List<DoctorAvailableSlotsDto>>> getSlotRange({
    required String scheduleId,
    required String from,
    required String to,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final slots = await _remoteDataSource.getSlotRange(
        scheduleId: scheduleId,
        from: from,
        to: to,
      );
      return Right(slots);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, DoctorAvailableSlotsDto>> getSlotsForDate({
    required String scheduleId,
    required String date,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final slots = await _remoteDataSource.getSlotsForDate(
        scheduleId: scheduleId,
        date: date,
      );
      return Right(slots);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, SlotHoldDto>> holdSlot({
    required String scheduleId,
    required String slotId,
    required String patientId,
    String? slotDate,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final hold = await _remoteDataSource.holdSlot(
        scheduleId: scheduleId,
        slotId: slotId,
        patientId: patientId,
        slotDate: slotDate,
      );
      return Right(hold);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, void>> releaseSlot({
    required String scheduleId,
    required String slotId,
    required String patientId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await _remoteDataSource.releaseSlot(
        scheduleId: scheduleId,
        slotId: slotId,
        patientId: patientId,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, String>> confirmBooking(
    ConfirmBookingRequest request,
  ) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final id = await _remoteDataSource.confirmBooking(request);
      return Right(id);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, MpesaInitiateResult>> initiateMpesaStk({
    required String branchId,
    required String phoneNumber,
    required double amount,
    String? slotId,
    String? patientId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final result = await _remoteDataSource.initiateMpesaStk(
        branchId: branchId,
        phoneNumber: phoneNumber,
        amount: amount,
        slotId: slotId,
        patientId: patientId,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }
}
