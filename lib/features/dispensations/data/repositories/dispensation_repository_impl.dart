import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/entities/dispensation_entity.dart';
import '../../domain/repositories/dispensation_repository.dart';
import '../datasources/dispensation_remote_datasource.dart';

class DispensationRepositoryImpl implements DispensationRepository {
  final DispensationRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  final SecureStorage? _secureStorage;

  DispensationRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
    SecureStorage? secureStorage,
  }) : _secureStorage = secureStorage;

  @override
  Future<Either<Failure, List<DispensationEntity>>> getDispensations({
    int page = 1,
    int pageSize = 50,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final patientId = await _secureStorage?.getPatientId();
      if (patientId == null || patientId.isEmpty) {
        return const Left(
          AuthFailure(message: 'Sign in as a patient to view dispensations.'),
        );
      }
      final list = await remoteDataSource.getDispensations(
        patientId: patientId,
        page: page,
        pageSize: pageSize,
      );
      return Right(list);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }
}
