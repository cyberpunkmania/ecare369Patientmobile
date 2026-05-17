import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/notification_entity.dart';
import '../repositories/notification_repository.dart';

class GetNotificationsUseCase {
  final NotificationRepository _repository;

  GetNotificationsUseCase({required NotificationRepository repository})
    : _repository = repository;

  Future<Either<Failure, List<NotificationEntity>>> call() =>
      _repository.getNotifications();
}
