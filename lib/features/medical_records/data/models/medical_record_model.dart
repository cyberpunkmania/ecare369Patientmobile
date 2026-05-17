import '../../domain/entities/medical_record_entity.dart';

class MedicalRecordModel extends MedicalRecordEntity {
  const MedicalRecordModel({
    required super.id,
    required super.title,
    required super.type,
    super.description,
    super.doctorName,
    required super.date,
    super.details,
    super.fileUrl,
  });

  factory MedicalRecordModel.fromJson(Map<String, dynamic> json) {
    return MedicalRecordModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      type: json['type'] as String? ?? 'visit_summary',
      description: json['description'] as String?,
      doctorName: json['doctorName'] as String?,
      date: DateTime.parse(
        json['date'] as String? ?? DateTime.now().toIso8601String(),
      ),
      details: json['details'] as Map<String, dynamic>?,
      fileUrl: json['fileUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'description': description,
      'doctorName': doctorName,
      'date': date.toIso8601String(),
      'details': details,
      'fileUrl': fileUrl,
    };
  }
}
