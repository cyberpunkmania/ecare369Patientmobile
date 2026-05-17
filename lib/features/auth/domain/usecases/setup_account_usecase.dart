import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/otp_response_entity.dart';
import '../entities/security_question_entity.dart';
import '../repositories/auth_repository.dart';

/// Use case for setting up a new account (Flow B - Step 2).
class SetupAccountUseCase {
  final AuthRepository _repository;

  SetupAccountUseCase({required AuthRepository repository})
    : _repository = repository;

  /// Sets up a new account with password and security questions.
  /// Returns [OtpResponseEntity] with OTP sent to email.
  ///
  /// For existing users (userId != null): Uses existing user record.
  /// For orphan patients (userId == null): Creates new User linked to Patient.
  Future<Either<Failure, OtpResponseEntity>> call({
    required String email,
    String? userId,
    required String password,
    required String confirmPassword,
    required List<SecurityQuestionAnswer> securityQuestions,
    String? patientId,
    String? tenantId,
  }) {
    return _repository.setupAccount(
      email: email,
      userId: userId,
      password: password,
      confirmPassword: confirmPassword,
      securityQuestions: securityQuestions,
      patientId: patientId,
      tenantId: tenantId,
    );
  }
}
