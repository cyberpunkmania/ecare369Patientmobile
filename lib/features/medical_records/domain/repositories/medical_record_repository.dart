import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/medical_record_entity.dart';

abstract class MedicalRecordRepository {
  Future<Either<Failure, List<MedicalRecordEntity>>> getMedicalRecords();
  Future<Either<Failure, MedicalRecordEntity>> getMedicalRecordById(String id);
}
