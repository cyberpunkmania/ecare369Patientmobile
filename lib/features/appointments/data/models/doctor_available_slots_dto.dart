import 'package:equatable/equatable.dart';

import 'appointment_slot_dto.dart';

class DoctorAvailableSlotsDto extends Equatable {
  final String scheduleId;
  final String doctorId;
  final String doctorName;
  final String specialization;
  final String date;
  final List<AppointmentSlotDto> availableSlots;
  final int totalAvailable;
  final bool isAtCapacity;

  const DoctorAvailableSlotsDto({
    required this.scheduleId,
    required this.doctorId,
    required this.doctorName,
    required this.specialization,
    required this.date,
    this.availableSlots = const [],
    this.totalAvailable = 0,
    this.isAtCapacity = false,
  });

  factory DoctorAvailableSlotsDto.fromJson(Map<String, dynamic> json) {
    return DoctorAvailableSlotsDto(
      scheduleId: json['scheduleId'] as String? ?? '',
      doctorId: json['doctorId'] as String? ?? '',
      doctorName: json['doctorName'] as String? ?? '',
      specialization: json['specialization'] as String? ?? '',
      date: json['date'] as String? ?? '',
      availableSlots:
          (json['slots'] as List<dynamic>?)
              ?.map(
                (e) => AppointmentSlotDto.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      totalAvailable: json['totalBookable'] as int? ?? 0,
      isAtCapacity: json['isAtCapacity'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [scheduleId, doctorId, date, totalAvailable];
}
