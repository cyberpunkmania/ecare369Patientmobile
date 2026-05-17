import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/queue_entities.dart';

abstract class QueueRepository {
  Future<Either<Failure, QueueLiveSnapshotEntity>> getLiveSnapshot(
    String branchId,
  );

  Future<Either<Failure, QueuePositionEntity?>> getMyPosition({
    required String branchId,
    required String patientId,
    DateTime? date,
  });
}
