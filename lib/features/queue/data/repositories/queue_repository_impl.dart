import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/queue_entities.dart';
import '../../domain/repositories/queue_repository.dart';
import '../datasources/queue_remote_datasource.dart';

class QueueRepositoryImpl implements QueueRepository {
  final QueueRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  QueueRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, QueueLiveSnapshotEntity>> getLiveSnapshot(
    String branchId,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final snap = await remoteDataSource.getLiveSnapshot(branchId);
      return Right(snap);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, QueuePositionEntity?>> getMyPosition({
    required String branchId,
    required String patientId,
    DateTime? date,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final pos = await remoteDataSource.getMyPosition(
        branchId: branchId,
        patientId: patientId,
        date: date,
      );
      return Right(pos);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }
}
