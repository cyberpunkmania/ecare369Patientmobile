import 'package:dartz/dartz.dart';

import '../../../../core/cache/cache_manager.dart';
import '../../../../core/cache/cache_policy.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_local_datasource.dart';
import '../datasources/notification_remote_datasource.dart';
import '../models/notification_model.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource _remoteDataSource;
  final NotificationLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;
  final CacheManager _cacheManager;

  static const _cacheKey = 'notifications_list';

  NotificationRepositoryImpl({
    required NotificationRemoteDataSource remoteDataSource,
    required NotificationLocalDataSource localDataSource,
    required NetworkInfo networkInfo,
    required CacheManager cacheManager,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource,
       _networkInfo = networkInfo,
       _cacheManager = cacheManager;

  @override
  Future<Either<Failure, List<NotificationEntity>>> getNotifications() async {
    try {
      final result = await _cacheManager.get<List<NotificationModel>>(
        key: _cacheKey,
        fetcher: () async {
          final notifications = await _remoteDataSource.getNotifications();
          await _localDataSource.cacheNotifications(notifications);
          return notifications;
        },
        policy: CachePolicy.networkFirst,
        ttl: const Duration(minutes: 2),
      );
      return Right(result);
    } on ServerException catch (e) {
      try {
        final cached = await _localDataSource.getCachedNotifications();
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
  Future<Either<Failure, void>> markAsRead(String id) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await _remoteDataSource.markAsRead(id);
      await _cacheManager.invalidate(_cacheKey);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> markAllAsRead() async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await _remoteDataSource.markAllAsRead();
      await _cacheManager.invalidate(_cacheKey);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }
}
