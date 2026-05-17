import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/otp_response_entity.dart';
import '../repositories/auth_repository.dart';

/// Use case for generating OTP after password verification (Flow A - Step 2).
class GenerateLoginOtpUseCase {
  final AuthRepository _repository;

  GenerateLoginOtpUseCase({required AuthRepository repository})
    : _repository = repository;

  /// Validates password and generates OTP for the selected account.
  /// Returns [OtpResponseEntity] with masked email and expiry info.
  Future<Either<Failure, OtpResponseEntity>> call({
    required String email,
    required String userId,
    required String password,
  }) {
    return _repository.generateLoginOtp(
      email: email,
      userId: userId,
      password: password,
    );
  }
}
