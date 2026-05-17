import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../data/models/confirm_booking_request.dart';
import '../../data/models/doctor_availability_dto.dart';
import '../../data/models/doctor_available_slots_dto.dart';
import '../../data/models/mpesa_initiate_result.dart';
import '../../data/models/patient_profile_dto.dart';
import '../../data/models/slot_hold_dto.dart';

abstract class BookingRepository {
  Future<Either<Failure, PatientProfileDto>> getPatientProfile(
    String patientId,
  );

  /// Tenant-scoped active doctor list (matches the web frontend).
  Future<Either<Failure, List<DoctorAvailabilityDto>>> getActiveDoctors({
    String? specialty,
  });

  /// Resolve the doctor's schedule id at a specific branch.
  Future<Either<Failure, String>> resolveScheduleId({
    required String doctorId,
    required String branchId,
  });

  Future<Either<Failure, List<DoctorAvailabilityDto>>> getAvailableDoctors({
    required String branchId,
    required String date,
    String? specialty,
    bool onlineOnly = true,
  });

  Future<Either<Failure, List<DoctorAvailableSlotsDto>>> getSlotRange({
    required String scheduleId,
    required String from,
    required String to,
  });

  Future<Either<Failure, DoctorAvailableSlotsDto>> getSlotsForDate({
    required String scheduleId,
    required String date,
  });

  Future<Either<Failure, SlotHoldDto>> holdSlot({
    required String scheduleId,
    required String slotId,
    required String patientId,
    String? slotDate,
  });

  Future<Either<Failure, void>> releaseSlot({
    required String scheduleId,
    required String slotId,
    required String patientId,
  });

  Future<Either<Failure, String>> confirmBooking(ConfirmBookingRequest request);

  /// Initiates an M-Pesa STK push for the booking fee. Should be called
  /// before [confirmBooking] so the patient pays first.
  Future<Either<Failure, MpesaInitiateResult>> initiateMpesaStk({
    required String branchId,
    required String phoneNumber,
    required double amount,
    String? slotId,
    String? patientId,
  });
}
