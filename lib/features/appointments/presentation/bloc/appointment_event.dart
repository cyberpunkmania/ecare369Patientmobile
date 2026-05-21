import 'package:equatable/equatable.dart';

abstract class AppointmentEvent extends Equatable {
  const AppointmentEvent();
  @override
  List<Object?> get props => [];
}

class AppointmentsLoaded extends AppointmentEvent {}

class AppointmentBooked extends AppointmentEvent {
  final String doctorId;
  final DateTime date;
  final String timeSlot;
  final String? type;
  final String? reason;

  const AppointmentBooked({
    required this.doctorId,
    required this.date,
    required this.timeSlot,
    this.type,
    this.reason,
  });

  @override
  List<Object?> get props => [doctorId, date, timeSlot, type, reason];
}

class AppointmentCancelled extends AppointmentEvent {
  final String id;
  final String reason;
  const AppointmentCancelled({
    required this.id,
    this.reason = 'Patient requested cancellation',
  });
  @override
  List<Object?> get props => [id, reason];
}
