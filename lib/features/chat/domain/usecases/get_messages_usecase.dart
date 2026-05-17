import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/message_entity.dart';
import '../repositories/chat_repository.dart';

class GetMessagesUseCase {
  final ChatRepository _repository;

  GetMessagesUseCase({required ChatRepository repository})
    : _repository = repository;

  Future<Either<Failure, List<MessageEntity>>> call(String conversationId) =>
      _repository.getMessages(conversationId);
}
