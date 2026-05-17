import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/auth_entity.dart';
import '../repositories/auth_repository.dart';

/// Use case for refreshing access tokens.
class RefreshTokenUseCase {
  final AuthRepository _repository;

  RefreshTokenUseCase({required AuthRepository repository})
    : _repository = repository;

  /// Refreshes the access token using the stored refresh token.
  /// Returns [TokenRefreshEntity] with new tokens on success.
  Future<Either<Failure, TokenRefreshEntity>> call() {
    return _repository.refreshToken();
  }
}
