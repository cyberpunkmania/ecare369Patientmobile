import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/message_entity.dart';
import '../repositories/chat_repository.dart';

class SendMessageUseCase {
  final ChatRepository _repository;

  SendMessageUseCase({required ChatRepository repository})
    : _repository = repository;

  Future<Either<Failure, MessageEntity>> call({
    required String conversationId,
    required String content,
    String type = 'text',
  }) => _repository.sendMessage(
    conversationId: conversationId,
    content: content,
    type: type,
  );
}
