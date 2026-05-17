import 'package:dartz/dartz.dart';

import '../../../../core/cache/cache_manager.dart';
import '../../../../core/cache/cache_policy.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/appointment_entity.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../datasources/appointment_local_datasource.dart';
import '../datasources/appointment_remote_datasource.dart';
import '../models/appointment_model.dart';
import '../models/my_appointment_dto.dart';

class AppointmentRepositoryImpl implements AppointmentRepository {
  final AppointmentRemoteDataSource _remoteDataSource;
  final AppointmentLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;
  final CacheManager _cacheManager;

  static const _appointmentsCacheKey = 'appointments_list';

  AppointmentRepositoryImpl({
    required AppointmentRemoteDataSource remoteDataSource,
    required AppointmentLocalDataSource localDataSource,
    required NetworkInfo networkInfo,
    required CacheManager cacheManager,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource,
       _networkInfo = networkInfo,
       _cacheManager = cacheManager;

  @override
  Future<Either<Failure, List<MyAppointmentDto>>> getAppointments() async {
    try {
      final result = await _cacheManager.get<List<MyAppointmentDto>>(
        key: _appointmentsCacheKey,
        fetcher: () async {
          final appointments = await _remoteDataSource.getAppointments();
          await _localDataSource.cacheAppointments(appointments);
          return appointments;
        },
        policy: CachePolicy.cacheFirst,
        ttl: const Duration(minutes: 5),
      );
      return Right(result);
    } on ServerException catch (e) {
      // Fallback to local cache.
      try {
        final cached = await _localDataSource.getCachedAppointments();
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
  Future<Either<Failure, AppointmentEntity>> getAppointmentById(
    String id,
  ) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final appointment = await _remoteDataSource.getAppointmentById(id);
      return Right(appointment);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, AppointmentEntity>> bookAppointment({
    required String doctorId,
    required DateTime date,
    required String timeSlot,
    String? type,
    String? reason,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final appointment = await _remoteDataSource.bookAppointment(
        doctorId: doctorId,
        date: date,
        timeSlot: timeSlot,
        type: type,
        reason: reason,
      );
      // Invalidate appointments list cache after write.
      await _cacheManager.invalidate(_appointmentsCacheKey);
      await _localDataSource.clearCache();
      return Right(appointment);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> cancelAppointment(String id, {String reason = ''}) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await _remoteDataSource.cancelAppointment(id, reason: reason);
      await _cacheManager.invalidate(_appointmentsCacheKey);
      await _localDataSource.clearCache();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, AppointmentEntity>> rescheduleAppointment({
    required String id,
    required DateTime newDate,
    required String newTimeSlot,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final appointment = await _remoteDataSource.rescheduleAppointment(
        id: id,
        newDate: newDate,
        newTimeSlot: newTimeSlot,
      );
      await _cacheManager.invalidate(_appointmentsCacheKey);
      await _localDataSource.clearCache();
      return Right(appointment);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }
}
