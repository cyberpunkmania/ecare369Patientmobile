import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/notification_repository.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/usecases/mark_notification_read_usecase.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final GetNotificationsUseCase _getNotifications;
  final MarkNotificationReadUseCase _markRead;
  final NotificationRepository _repository;

  NotificationBloc({
    required GetNotificationsUseCase getNotifications,
    required MarkNotificationReadUseCase markRead,
    required NotificationRepository repository,
  }) : _getNotifications = getNotifications,
       _markRead = markRead,
       _repository = repository,
       super(NotificationInitial()) {
    on<NotificationsLoadRequested>(_onLoad);
    on<NotificationMarkReadRequested>(_onMarkRead);
    on<NotificationsMarkAllReadRequested>(_onMarkAllRead);
  }

  Future<void> _onLoad(
    NotificationsLoadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    final result = await _getNotifications();
    result.fold(
      (failure) => emit(NotificationError(message: failure.message)),
      (notifications) =>
          emit(NotificationListLoaded(notifications: notifications)),
    );
  }

  Future<void> _onMarkRead(
    NotificationMarkReadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    await _markRead(event.notificationId);
    add(const NotificationsLoadRequested());
  }

  Future<void> _onMarkAllRead(
    NotificationsMarkAllReadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    await _repository.markAllAsRead();
    add(const NotificationsLoadRequested());
  }
}
