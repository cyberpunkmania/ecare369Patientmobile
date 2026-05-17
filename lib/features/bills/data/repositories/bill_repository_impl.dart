import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/entities/bill_entity.dart';
import '../../domain/repositories/bill_repository.dart';
import '../datasources/bill_remote_datasource.dart';

class BillRepositoryImpl implements BillRepository {
  final BillRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  final SecureStorage secureStorage;

  BillRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
    required this.secureStorage,
  });

  @override
  Future<Either<Failure, List<BillEntity>>> getBills({
    int page = 1,
    int pageSize = 50,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final patientId = await secureStorage.getPatientId();
      if (patientId == null || patientId.isEmpty) {
        return const Left(
          AuthFailure(message: 'Sign in as a patient to view bills.'),
        );
      }
      final list = await remoteDataSource.getBills(
        patientId: patientId,
        page: page,
        pageSize: pageSize,
      );
      return Right(list);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, BillEntity>> getBillById(String id) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final b = await remoteDataSource.getBillById(id);
      return Right(b);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }
}
