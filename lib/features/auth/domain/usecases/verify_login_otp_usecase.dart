import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/auth_entity.dart';
import '../repositories/auth_repository.dart';

/// Use case for verifying OTP and completing login (Flow A - Step 3).
class VerifyLoginOtpUseCase {
  final AuthRepository _repository;

  VerifyLoginOtpUseCase({required AuthRepository repository})
    : _repository = repository;

  /// Verifies the OTP and completes the login process.
  /// Returns [AuthEntity] with tokens and user data on success.
  Future<Either<Failure, AuthEntity>> call({
    required String userId,
    required String otpCode,
  }) {
    return _repository.verifyLoginOtp(userId: userId, otpCode: otpCode);
  }
}
