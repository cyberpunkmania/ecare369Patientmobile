import 'package:equatable/equatable.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();
  @override
  List<Object?> get props => [];
}

class NotificationsLoadRequested extends NotificationEvent {
  const NotificationsLoadRequested();
}

class NotificationMarkReadRequested extends NotificationEvent {
  final String notificationId;
  const NotificationMarkReadRequested({required this.notificationId});
  @override
  List<Object?> get props => [notificationId];
}

class NotificationsMarkAllReadRequested extends NotificationEvent {
  const NotificationsMarkAllReadRequested();
}
