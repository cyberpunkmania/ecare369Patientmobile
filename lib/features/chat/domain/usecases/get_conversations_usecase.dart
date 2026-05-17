import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/conversation_entity.dart';
import '../repositories/chat_repository.dart';

class GetConversationsUseCase {
  final ChatRepository _repository;

  GetConversationsUseCase({required ChatRepository repository})
    : _repository = repository;

  Future<Either<Failure, List<ConversationEntity>>> call() =>
      _repository.getConversations();
}
