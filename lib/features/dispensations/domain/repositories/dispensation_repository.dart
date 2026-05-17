import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/dispensation_entity.dart';

abstract class DispensationRepository {
  Future<Either<Failure, List<DispensationEntity>>> getDispensations({
    int page = 1,
    int pageSize = 50,
  });
}
