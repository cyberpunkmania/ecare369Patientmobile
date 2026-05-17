import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/appointment_entity.dart';
import '../repositories/appointment_repository.dart';

class BookAppointmentUseCase {
  final AppointmentRepository _repository;

  BookAppointmentUseCase({required AppointmentRepository repository})
    : _repository = repository;

  Future<Either<Failure, AppointmentEntity>> call({
    required String doctorId,
    required DateTime date,
    required String timeSlot,
    String? type,
    String? reason,
  }) {
    return _repository.bookAppointment(
      doctorId: doctorId,
      date: date,
      timeSlot: timeSlot,
      type: type,
      reason: reason,
    );
  }
}
