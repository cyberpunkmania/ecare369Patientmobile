import 'package:dartz/dartz.dart';

import '../../../../core/cache/cache_manager.dart';
import '../../../../core/cache/cache_policy.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/medical_record_entity.dart';
import '../../domain/repositories/medical_record_repository.dart';
import '../datasources/medical_record_local_datasource.dart';
import '../datasources/medical_record_remote_datasource.dart';
import '../models/medical_record_model.dart';

class MedicalRecordRepositoryImpl implements MedicalRecordRepository {
  final MedicalRecordRemoteDataSource _remoteDataSource;
  final MedicalRecordLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;
  final CacheManager _cacheManager;

  static const _cacheKey = 'medical_records_list';

  MedicalRecordRepositoryImpl({
    required MedicalRecordRemoteDataSource remoteDataSource,
    required MedicalRecordLocalDataSource localDataSource,
    required NetworkInfo networkInfo,
    required CacheManager cacheManager,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource,
       _networkInfo = networkInfo,
       _cacheManager = cacheManager;

  @override
  Future<Either<Failure, List<MedicalRecordEntity>>> getMedicalRecords() async {
    try {
      final result = await _cacheManager.get<List<MedicalRecordModel>>(
        key: _cacheKey,
        fetcher: () async {
          final records = await _remoteDataSource.getMedicalRecords();
          await _localDataSource.cacheRecords(records);
          return records;
        },
        policy: CachePolicy.cacheFirst,
        ttl: const Duration(minutes: 30),
      );
      return Right(result);
    } on ServerException catch (e) {
      try {
        final cached = await _localDataSource.getCachedRecords();
        return Right(cached);
      } catch (_) {
        return Left(ServerFailure(message: e.message));
      }
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, MedicalRecordEntity>> getMedicalRecordById(
    String id,
  ) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final record = await _remoteDataSource.getMedicalRecordById(id);
      return Right(record);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }
}
