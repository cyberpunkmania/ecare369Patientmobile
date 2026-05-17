import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

/// Use case for fetching available security questions (Flow B - Step 1).
class GetSecurityQuestionsUseCase {
  final AuthRepository _repository;

  GetSecurityQuestionsUseCase({required AuthRepository repository})
    : _repository = repository;

  /// Fetches the list of available security questions for account setup.
  /// Returns a list of 3 randomly selected question strings.
  Future<Either<Failure, List<String>>> call() {
    return _repository.getSecurityQuestions();
  }
}
