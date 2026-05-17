import 'package:equatable/equatable.dart';

class AppointmentEntity extends Equatable {
  final String id;
  final String doctorId;
  final String doctorName;
  final String? doctorSpecialty;
  final String? doctorAvatarUrl;
  final DateTime appointmentDate;
  final String timeSlot;
  final String status; // scheduled, completed, cancelled, rescheduled
  final String? type; // in-person, video, phone
  final String? reason;
  final String? notes;
  final DateTime? createdAt;

  const AppointmentEntity({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    this.doctorSpecialty,
    this.doctorAvatarUrl,
    required this.appointmentDate,
    required this.timeSlot,
    required this.status,
    this.type,
    this.reason,
    this.notes,
    this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    doctorId,
    doctorName,
    doctorSpecialty,
    appointmentDate,
    timeSlot,
    status,
    type,
    reason,
    notes,
  ];
}
