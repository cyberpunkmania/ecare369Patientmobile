import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_conversations_usecase.dart';
import '../../domain/usecases/get_messages_usecase.dart';
import '../../domain/usecases/send_message_usecase.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GetConversationsUseCase _getConversations;
  final GetMessagesUseCase _getMessages;
  final SendMessageUseCase _sendMessage;

  ChatBloc({
    required GetConversationsUseCase getConversations,
    required GetMessagesUseCase getMessages,
    required SendMessageUseCase sendMessage,
  }) : _getConversations = getConversations,
       _getMessages = getMessages,
       _sendMessage = sendMessage,
       super(ChatInitial()) {
    on<ConversationsLoadRequested>(_onLoadConversations);
    on<MessagesLoadRequested>(_onLoadMessages);
    on<SendMessageRequested>(_onSendMessage);
  }

  Future<void> _onLoadConversations(
    ConversationsLoadRequested event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    final result = await _getConversations();
    result.fold(
      (failure) => emit(ChatError(message: failure.message)),
      (conversations) =>
          emit(ConversationsLoaded(conversations: conversations)),
    );
  }

  Future<void> _onLoadMessages(
    MessagesLoadRequested event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    final result = await _getMessages(event.conversationId);
    result.fold(
      (failure) => emit(ChatError(message: failure.message)),
      (messages) => emit(
        MessagesLoaded(
          conversationId: event.conversationId,
          messages: messages,
        ),
      ),
    );
  }

  Future<void> _onSendMessage(
    SendMessageRequested event,
    Emitter<ChatState> emit,
  ) async {
    final result = await _sendMessage(
      conversationId: event.conversationId,
      content: event.content,
      type: event.type,
    );
    result.fold((failure) => emit(ChatError(message: failure.message)), (
      message,
    ) {
      emit(MessageSent(message: message));
      // Reload messages after send
      add(MessagesLoadRequested(conversationId: event.conversationId));
    });
  }
}
