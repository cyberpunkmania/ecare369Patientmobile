import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/medical_record_entity.dart';
import '../repositories/medical_record_repository.dart';

class GetMedicalRecordsUseCase {
  final MedicalRecordRepository _repository;

  GetMedicalRecordsUseCase({required MedicalRecordRepository repository})
    : _repository = repository;

  Future<Either<Failure, List<MedicalRecordEntity>>> call() =>
      _repository.getMedicalRecords();
}
