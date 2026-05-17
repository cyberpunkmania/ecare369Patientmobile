import 'package:equatable/equatable.dart';

class SlotHoldDto extends Equatable {
  final String scheduleId;
  final String slotId;
  final String patientId;
  final String date;
  final String startTime;
  final String endTime;
  final String doctorName;
  final String specialization;
  final String holdExpiresAt;
  final int holdMinutes;

  const SlotHoldDto({
    required this.scheduleId,
    required this.slotId,
    required this.patientId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.doctorName,
    required this.specialization,
    required this.holdExpiresAt,
    this.holdMinutes = 10,
  });

  factory SlotHoldDto.fromJson(Map<String, dynamic> json) {
    return SlotHoldDto(
      scheduleId: json['scheduleId'] as String? ?? '',
      slotId: json['slotId'] as String? ?? '',
      patientId: json['patientId'] as String? ?? '',
      date: json['date'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      doctorName: json['doctorName'] as String? ?? '',
      specialization: json['specialization'] as String? ?? '',
      holdExpiresAt: json['holdExpiresAt'] as String? ?? '',
      holdMinutes: json['holdMinutes'] as int? ?? 10,
    );
  }

  @override
  List<Object?> get props => [scheduleId, slotId, patientId, holdExpiresAt];
}
