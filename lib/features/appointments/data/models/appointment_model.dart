import '../../domain/entities/appointment_entity.dart';

class AppointmentModel extends AppointmentEntity {
  const AppointmentModel({
    required super.id,
    required super.doctorId,
    required super.doctorName,
    super.doctorSpecialty,
    super.doctorAvatarUrl,
    required super.appointmentDate,
    required super.timeSlot,
    required super.status,
    super.type,
    super.reason,
    super.notes,
    super.createdAt,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      doctorId: json['doctorId'] as String? ?? '',
      doctorName: json['doctorName'] as String? ?? '',
      doctorSpecialty: json['doctorSpecialty'] as String?,
      doctorAvatarUrl: json['doctorAvatarUrl'] as String?,
      appointmentDate: DateTime.parse(
        json['appointmentDate'] as String? ?? DateTime.now().toIso8601String(),
      ),
      timeSlot: json['timeSlot'] as String? ?? '',
      status: json['status'] as String? ?? 'scheduled',
      type: json['type'] as String?,
      reason: json['reason'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'doctorSpecialty': doctorSpecialty,
      'doctorAvatarUrl': doctorAvatarUrl,
      'appointmentDate': appointmentDate.toIso8601String(),
      'timeSlot': timeSlot,
      'status': status,
      'type': type,
      'reason': reason,
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
