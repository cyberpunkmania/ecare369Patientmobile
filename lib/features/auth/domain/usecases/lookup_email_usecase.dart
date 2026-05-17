import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/lookup_result_entity.dart';
import '../repositories/auth_repository.dart';

/// Use case for looking up user accounts by email address.
/// This is the common entry point for all authentication flows.
class LookupEmailUseCase {
  final AuthRepository _repository;

  LookupEmailUseCase({required AuthRepository repository})
    : _repository = repository;

  /// Looks up accounts associated with the given email.
  /// Returns [LookupResultEntity] containing categorized accounts.
  Future<Either<Failure, LookupResultEntity>> call({required String email}) {
    return _repository.lookupEmail(email: email);
  }
}
