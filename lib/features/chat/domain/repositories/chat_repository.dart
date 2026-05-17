import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/conversation_entity.dart';
import '../entities/message_entity.dart';

abstract class ChatRepository {
  Future<Either<Failure, List<ConversationEntity>>> getConversations();
  Future<Either<Failure, List<MessageEntity>>> getMessages(
    String conversationId,
  );
  Future<Either<Failure, MessageEntity>> sendMessage({
    required String conversationId,
    required String content,
    String type = 'text',
  });
}
