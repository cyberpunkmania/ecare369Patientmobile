import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/appointment_repository.dart';

class CancelAppointmentUseCase {
  final AppointmentRepository _repository;

  CancelAppointmentUseCase({required AppointmentRepository repository})
    : _repository = repository;

  Future<Either<Failure, void>> call(String id, {String reason = ''}) =>
      _repository.cancelAppointment(id, reason: reason);
}
