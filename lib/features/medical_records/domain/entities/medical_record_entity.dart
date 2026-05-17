import 'package:equatable/equatable.dart';

class MedicalRecordEntity extends Equatable {
  final String id;
  final String title;
  final String type; // lab_result, prescription, diagnosis, visit_summary
  final String? description;
  final String? doctorName;
  final DateTime date;
  final Map<String, dynamic>? details;
  final String? fileUrl;

  const MedicalRecordEntity({
    required this.id,
    required this.title,
    required this.type,
    this.description,
    this.doctorName,
    required this.date,
    this.details,
    this.fileUrl,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    type,
    description,
    doctorName,
    date,
    fileUrl,
  ];
}
