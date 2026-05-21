import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../data/models/my_appointment_dto.dart';
import '../entities/appointment_entity.dart';

abstract class AppointmentRepository {
  Future<Either<Failure, List<MyAppointmentDto>>> getAppointments();
  Future<Either<Failure, AppointmentEntity>> getAppointmentById(String id);
  Future<Either<Failure, AppointmentEntity>> bookAppointment({
    required String doctorId,
    required DateTime date,
    required String timeSlot,
    String? type,
    String? reason,
  });
  Future<Either<Failure, void>> cancelAppointment(
    String id, {
    String reason = '',
  });
  Future<Either<Failure, AppointmentEntity>> rescheduleAppointment({
    required String id,
    required DateTime newDate,
    required String newTimeSlot,
  });
}
