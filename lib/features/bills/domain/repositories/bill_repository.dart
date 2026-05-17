import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/bill_entity.dart';

abstract class BillRepository {
  Future<Either<Failure, List<BillEntity>>> getBills({
    int page = 1,
    int pageSize = 50,
  });
  Future<Either<Failure, BillEntity>> getBillById(String id);
}
