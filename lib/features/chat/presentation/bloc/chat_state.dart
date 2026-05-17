import 'package:equatable/equatable.dart';

import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_entity.dart';

abstract class ChatState extends Equatable {
  const ChatState();
  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ConversationsLoaded extends ChatState {
  final List<ConversationEntity> conversations;
  const ConversationsLoaded({required this.conversations});
  @override
  List<Object?> get props => [conversations];
}

class MessagesLoaded extends ChatState {
  final String conversationId;
  final List<MessageEntity> messages;
  const MessagesLoaded({required this.conversationId, required this.messages});
  @override
  List<Object?> get props => [conversationId, messages];
}

class MessageSent extends ChatState {
  final MessageEntity message;
  const MessageSent({required this.message});
  @override
  List<Object?> get props => [message];
}

class ChatError extends ChatState {
  final String message;
  const ChatError({required this.message});
  @override
  List<Object?> get props => [message];
}
