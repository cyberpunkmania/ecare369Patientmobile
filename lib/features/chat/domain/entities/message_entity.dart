import 'package:equatable/equatable.dart';

class MessageEntity extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderRole; // patient | doctor
  final String content;
  final String type; // text, image, file
  final DateTime createdAt;
  final bool isRead;

  const MessageEntity({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderRole,
    required this.content,
    this.type = 'text',
    required this.createdAt,
    this.isRead = false,
  });

  @override
  List<Object?> get props => [
    id,
    conversationId,
    senderId,
    content,
    createdAt,
    isRead,
  ];
}
