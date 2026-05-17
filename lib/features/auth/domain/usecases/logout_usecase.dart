import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

class LogoutUseCase {
  final AuthRepository _repository;

  LogoutUseCase({required AuthRepository repository})
    : _repository = repository;

  Future<Either<Failure, void>> call() => _repository.logout();
}
