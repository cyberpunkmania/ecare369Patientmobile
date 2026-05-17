import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../data/models/my_appointment_dto.dart';
import '../repositories/appointment_repository.dart';

class GetAppointmentsUseCase {
  final AppointmentRepository _repository;

  GetAppointmentsUseCase({required AppointmentRepository repository})
    : _repository = repository;

  Future<Either<Failure, List<MyAppointmentDto>>> call() =>
      _repository.getAppointments();
}
