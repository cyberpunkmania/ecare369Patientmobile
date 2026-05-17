import 'package:equatable/equatable.dart';

class ConversationEntity extends Equatable {
  final String id;
  final String doctorId;
  final String doctorName;
  final String? doctorAvatarUrl;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  const ConversationEntity({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    this.doctorAvatarUrl,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  @override
  List<Object?> get props => [
    id,
    doctorId,
    doctorName,
    lastMessage,
    lastMessageAt,
    unreadCount,
  ];
}
