import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/medical_record_repository.dart';
import '../../domain/usecases/get_medical_records_usecase.dart';
import 'medical_record_event.dart';
import 'medical_record_state.dart';

class MedicalRecordBloc extends Bloc<MedicalRecordEvent, MedicalRecordState> {
  final GetMedicalRecordsUseCase _getMedicalRecords;
  final MedicalRecordRepository _repository;

  MedicalRecordBloc({
    required GetMedicalRecordsUseCase getMedicalRecords,
    required MedicalRecordRepository repository,
  }) : _getMedicalRecords = getMedicalRecords,
       _repository = repository,
       super(MedicalRecordInitial()) {
    on<MedicalRecordsLoadRequested>(_onLoad);
    on<MedicalRecordDetailRequested>(_onDetail);
  }

  Future<void> _onLoad(
    MedicalRecordsLoadRequested event,
    Emitter<MedicalRecordState> emit,
  ) async {
    emit(MedicalRecordLoading());
    final result = await _getMedicalRecords();
    result.fold(
      (failure) => emit(MedicalRecordError(message: failure.message)),
      (records) => emit(MedicalRecordListLoaded(records: records)),
    );
  }

  Future<void> _onDetail(
    MedicalRecordDetailRequested event,
    Emitter<MedicalRecordState> emit,
  ) async {
    emit(MedicalRecordLoading());
    final result = await _repository.getMedicalRecordById(event.recordId);
    result.fold(
      (failure) => emit(MedicalRecordError(message: failure.message)),
      (record) => emit(MedicalRecordDetailLoaded(record: record)),
    );
  }
}
