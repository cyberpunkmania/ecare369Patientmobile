import 'package:equatable/equatable.dart';

abstract class MedicalRecordEvent extends Equatable {
  const MedicalRecordEvent();

  @override
  List<Object?> get props => [];
}

class MedicalRecordsLoadRequested extends MedicalRecordEvent {
  const MedicalRecordsLoadRequested();
}

class MedicalRecordDetailRequested extends MedicalRecordEvent {
  final String recordId;

  const MedicalRecordDetailRequested({required this.recordId});

  @override
  List<Object?> get props => [recordId];
}
