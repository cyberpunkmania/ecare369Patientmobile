import 'package:equatable/equatable.dart';

import '../../data/models/my_appointment_dto.dart';
import '../../domain/entities/appointment_entity.dart';

abstract class AppointmentState extends Equatable {
  const AppointmentState();
  @override
  List<Object?> get props => [];
}

class AppointmentInitial extends AppointmentState {}

class AppointmentLoading extends AppointmentState {}

class AppointmentListLoaded extends AppointmentState {
  final List<MyAppointmentDto> appointments;
  const AppointmentListLoaded({required this.appointments});
  @override
  List<Object?> get props => [appointments];
}

class AppointmentBookedSuccess extends AppointmentState {
  final AppointmentEntity appointment;
  const AppointmentBookedSuccess({required this.appointment});
  @override
  List<Object?> get props => [appointment];
}

class AppointmentCancelledSuccess extends AppointmentState {}

class AppointmentError extends AppointmentState {
  final String message;
  const AppointmentError({required this.message});
  @override
  List<Object?> get props => [message];
}
