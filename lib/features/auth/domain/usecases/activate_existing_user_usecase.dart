import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/auth_entity.dart';
import '../entities/security_question_entity.dart';
import '../repositories/auth_repository.dart';

/// Use case for activating an existing inactive account (Flow C - Step 2).
class ActivateExistingUserUseCase {
  final AuthRepository _repository;

  ActivateExistingUserUseCase({required AuthRepository repository})
    : _repository = repository;

  /// Activates an inactive account by verifying security answers and setting new password.
  /// Returns [AuthEntity] with tokens and user data on success.
  Future<Either<Failure, AuthEntity>> call({
    required String email,
    required String tenantId,
    required String newPassword,
    required List<SecurityQuestionAnswer> securityAnswers,
  }) {
    return _repository.activateExistingUser(
      email: email,
      tenantId: tenantId,
      newPassword: newPassword,
      securityAnswers: securityAnswers,
    );
  }
}
