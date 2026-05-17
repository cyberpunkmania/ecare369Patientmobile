import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/auth_entity.dart';
import '../entities/lookup_result_entity.dart';
import '../entities/otp_response_entity.dart';
import '../entities/patient_registration_entity.dart';
import '../entities/security_question_entity.dart';
import '../entities/user_entity.dart';

/// Abstract contract for multi-flow auth operations.
///
/// Supports two registration paths:
/// - Path A (Full Self-Registration): Register with password → Lookup → Setup → Confirm
/// - Path B (Orphan Patient): Lookup (userId=null) → Setup (creates user) → Confirm
///
/// And three login flows:
/// - Flow A (Active): Email lookup → Password → OTP verification
/// - Flow B (Onboarding): Email lookup → Account setup → OTP confirmation
/// - Flow C (Inactive): Email lookup → Security Q&A → Password reset
abstract class AuthRepository {
  // ══════════════════════════════════════════════════════════════════════════
  // ── Patient Registration ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Register a new patient (Path A: Full Self-Registration).
  /// Creates both Patient and User records when patientType = PatientUser.
  Future<Either<Failure, PatientEntity>> registerPatient({
    required PatientRegistrationRequest request,
  });

  // ══════════════════════════════════════════════════════════════════════════
  // ── Email Lookup (Common entry point for all flows) ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Lookup user accounts by email address.
  /// Returns available accounts categorized by status.
  /// For orphan patients, accounts have userId = null.
  Future<Either<Failure, LookupResultEntity>> lookupEmail({
    required String email,
  });

  // ══════════════════════════════════════════════════════════════════════════
  // ── Flow A: Active User Login ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Generate OTP after password verification for active user login.
  /// Request: { email, userId, password }
  Future<Either<Failure, OtpResponseEntity>> generateLoginOtp({
    required String email,
    required String userId,
    required String password,
  });

  /// Verify OTP and complete login for active users.
  /// Request: { userId, otpCode }
  Future<Either<Failure, AuthEntity>> verifyLoginOtp({
    required String userId,
    required String otpCode,
  });

  // ══════════════════════════════════════════════════════════════════════════
  // ── Flow B: New Account Onboarding ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Fetch available security questions for new account setup.
  /// Returns a list of 3 randomly selected security question strings.
  Future<Either<Failure, List<String>>> getSecurityQuestions();

  /// Setup new account with password and security questions.
  ///
  /// For existing users (userId != null):
  ///   - Uses the existing user record
  ///
  /// For orphan patients (userId == null):
  ///   - Requires patientId and tenantId
  ///   - Creates a new User and links to Patient
  Future<Either<Failure, OtpResponseEntity>> setupAccount({
    required String email,
    String? userId,
    required String password,
    required String confirmPassword,
    required List<SecurityQuestionAnswer> securityQuestions,
    String? patientId,
    String? tenantId,
  });

  /// Confirm onboarding with OTP verification.
  /// Request: { email, userId, otpCode, patientId? }
  Future<Either<Failure, AuthEntity>> confirmOnboarding({
    required String email,
    required String userId,
    required String otpCode,
    String? patientId,
  });

  // ══════════════════════════════════════════════════════════════════════════
  // ── Flow C: Inactive Account Reactivation ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Fetch user's security questions for account reactivation.
  Future<Either<Failure, UserSecurityQuestionsEntity>>
  fetchUserSecurityQuestions({required String email, required String tenantId});

  /// Reactivate inactive account with security answers and new password.
  Future<Either<Failure, AuthEntity>> activateExistingUser({
    required String email,
    required String tenantId,
    required String newPassword,
    required List<SecurityQuestionAnswer> securityAnswers,
  });

  // ══════════════════════════════════════════════════════════════════════════
  // ── Token Management ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Refresh access token using refresh token.
  Future<Either<Failure, TokenRefreshEntity>> refreshToken();

  // ══════════════════════════════════════════════════════════════════════════
  // ── Session Management ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Retrieve stored user (if logged in).
  Future<Either<Failure, UserEntity>> getCurrentUser();

  /// Clear local session and invalidate tokens.
  Future<Either<Failure, void>> logout();

  /// Returns `true` when a valid auth token is stored.
  Future<bool> isLoggedIn();

  /// Check if the current token is expired or about to expire.
  Future<bool> isTokenExpired();

  /// Get the stored account context (tenantId, branchId).
  Future<Either<Failure, Map<String, String>>> getAccountContext();

  /// Persist the selected tenant/branch so subsequent requests carry X-Tenant-ID.
  Future<void> saveAccountContext({required String tenantId, String? branchId});
}
