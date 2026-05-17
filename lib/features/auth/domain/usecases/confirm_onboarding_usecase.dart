import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/auth_entity.dart';
import '../repositories/auth_repository.dart';

/// Use case for confirming onboarding with OTP (Flow B - Step 3).
class ConfirmOnboardingUseCase {
  final AuthRepository _repository;

  ConfirmOnboardingUseCase({required AuthRepository repository})
    : _repository = repository;

  /// Confirms onboarding by verifying the OTP.
  /// Returns [AuthEntity] with tokens and user data on success.
  Future<Either<Failure, AuthEntity>> call({
    required String email,
    required String userId,
    required String otpCode,
    String? patientId,
  }) {
    return _repository.confirmOnboarding(
      email: email,
      userId: userId,
      otpCode: otpCode,
      patientId: patientId,
    );
  }
}
