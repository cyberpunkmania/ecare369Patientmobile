import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object?> get props => [];
}

class ConversationsLoadRequested extends ChatEvent {
  const ConversationsLoadRequested();
}

class MessagesLoadRequested extends ChatEvent {
  final String conversationId;
  const MessagesLoadRequested({required this.conversationId});
  @override
  List<Object?> get props => [conversationId];
}

class SendMessageRequested extends ChatEvent {
  final String conversationId;
  final String content;
  final String type;

  const SendMessageRequested({
    required this.conversationId,
    required this.content,
    this.type = 'text',
  });

  @override
  List<Object?> get props => [conversationId, content, type];
}
