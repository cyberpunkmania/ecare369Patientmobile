import 'package:equatable/equatable.dart';

import '../../domain/entities/medical_record_entity.dart';

abstract class MedicalRecordState extends Equatable {
  const MedicalRecordState();

  @override
  List<Object?> get props => [];
}

class MedicalRecordInitial extends MedicalRecordState {}

class MedicalRecordLoading extends MedicalRecordState {}

class MedicalRecordListLoaded extends MedicalRecordState {
  final List<MedicalRecordEntity> records;

  const MedicalRecordListLoaded({required this.records});

  @override
  List<Object?> get props => [records];
}

class MedicalRecordDetailLoaded extends MedicalRecordState {
  final MedicalRecordEntity record;

  const MedicalRecordDetailLoaded({required this.record});

  @override
  List<Object?> get props => [record];
}

class MedicalRecordError extends MedicalRecordState {
  final String message;

  const MedicalRecordError({required this.message});

  @override
  List<Object?> get props => [message];
}
