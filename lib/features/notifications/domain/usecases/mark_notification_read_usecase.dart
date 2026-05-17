import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/notification_repository.dart';

class MarkNotificationReadUseCase {
  final NotificationRepository _repository;

  MarkNotificationReadUseCase({required NotificationRepository repository})
    : _repository = repository;

  Future<Either<Failure, void>> call(String id) => _repository.markAsRead(id);
}
