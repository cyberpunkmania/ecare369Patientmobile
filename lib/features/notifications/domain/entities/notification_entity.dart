import 'package:equatable/equatable.dart';

class NotificationEntity extends Equatable {
  final String id;
  final String title;
  final String body;
  final String type; // appointment, chat, system, result
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  const NotificationEntity({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.isRead = false,
    required this.createdAt,
    this.data,
  });

  @override
  List<Object?> get props => [id, title, body, type, isRead, createdAt];
}
