import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/security_question_entity.dart';
import '../repositories/auth_repository.dart';

/// Use case for fetching user's security questions for reactivation (Flow C - Step 1).
class FetchUserSecurityQuestionsUseCase {
  final AuthRepository _repository;

  FetchUserSecurityQuestionsUseCase({required AuthRepository repository})
    : _repository = repository;

  /// Fetches the security questions previously set by the user.
  /// Returns [UserSecurityQuestionsEntity] with questions to answer.
  Future<Either<Failure, UserSecurityQuestionsEntity>> call({
    required String email,
    required String tenantId,
  }) {
    return _repository.fetchUserSecurityQuestions(
      email: email,
      tenantId: tenantId,
    );
  }
}
