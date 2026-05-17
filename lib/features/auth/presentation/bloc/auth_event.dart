import 'package:equatable/equatable.dart';

import '../../domain/entities/account_option_entity.dart';
import '../../domain/entities/patient_registration_entity.dart';
import '../../domain/entities/security_question_entity.dart';

/// Base class for all auth events.
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

// ══════════════════════════════════════════════════════════════════════════
// ── Patient Registration Events ──
// ══════════════════════════════════════════════════════════════════════════

/// User submitted patient registration form.
class PatientRegistrationRequested extends AuthEvent {
  final PatientRegistrationRequest request;

  const PatientRegistrationRequested({required this.request});

  @override
  List<Object?> get props => [request];
}

// ══════════════════════════════════════════════════════════════════════════
// ── Session Management Events ──
// ══════════════════════════════════════════════════════════════════════════

/// Check stored session on app start.
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// User requested logout.
class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// Reset auth flow to initial state (e.g., user wants to start over).
class AuthResetRequested extends AuthEvent {
  const AuthResetRequested();
}

/// Navigate back one step in the auth flow.
class AuthBackRequested extends AuthEvent {
  const AuthBackRequested();
}

// ══════════════════════════════════════════════════════════════════════════
// ── Email Lookup Events ──
// ══════════════════════════════════════════════════════════════════════════

/// User submitted email for lookup.
class LookupEmailRequested extends AuthEvent {
  final String email;

  const LookupEmailRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

/// User selected an account from the account picker.
/// This determines which auth flow to follow.
class AccountSelected extends AuthEvent {
  final AccountOptionEntity account;

  const AccountSelected({required this.account});

  @override
  List<Object?> get props => [account];
}

// ══════════════════════════════════════════════════════════════════════════
// ── Flow A: Active User Login Events ──
// ══════════════════════════════════════════════════════════════════════════

/// User submitted password for active account login (Flow A - Step 2).
class PasswordSubmitted extends AuthEvent {
  final String password;

  const PasswordSubmitted({required this.password});

  @override
  List<Object?> get props => [password];
}

/// User submitted OTP for verification (Flow A - Step 3 / Flow B - Step 3).
class OtpSubmitted extends AuthEvent {
  final String otp;

  const OtpSubmitted({required this.otp});

  @override
  List<Object?> get props => [otp];
}

/// User requested to resend OTP.
class ResendOtpRequested extends AuthEvent {
  const ResendOtpRequested();
}

// ══════════════════════════════════════════════════════════════════════════
// ── Flow B: Onboarding Events ──
// ══════════════════════════════════════════════════════════════════════════

/// Request to fetch security questions for new account setup (Flow B - Step 1).
class FetchSecurityQuestionsRequested extends AuthEvent {
  const FetchSecurityQuestionsRequested();
}

/// Background fetch of more security questions for the pool.
class FetchMoreSecurityQuestionsRequested extends AuthEvent {
  const FetchMoreSecurityQuestionsRequested();
}

/// User submitted new account setup with password and security questions (Flow B - Step 2).
class AccountSetupSubmitted extends AuthEvent {
  final String password;
  final List<SecurityQuestionAnswer> securityQuestions;

  const AccountSetupSubmitted({
    required this.password,
    required this.securityQuestions,
  });

  @override
  List<Object?> get props => [password, securityQuestions];
}

// ══════════════════════════════════════════════════════════════════════════
// ── Flow C: Reactivation Events ──
// ══════════════════════════════════════════════════════════════════════════

/// Request to fetch user's security questions for reactivation (Flow C - Step 1).
class FetchUserSecurityQuestionsRequested extends AuthEvent {
  const FetchUserSecurityQuestionsRequested();
}

/// User submitted security answers and new password for reactivation (Flow C - Step 2).
class ReactivationSubmitted extends AuthEvent {
  final String newPassword;
  final List<SecurityQuestionAnswer> securityAnswers;

  const ReactivationSubmitted({
    required this.newPassword,
    required this.securityAnswers,
  });

  @override
  List<Object?> get props => [newPassword, securityAnswers];
}

// ══════════════════════════════════════════════════════════════════════════
// ── Token Management Events ──
// ══════════════════════════════════════════════════════════════════════════

/// Request to refresh the access token.
class TokenRefreshRequested extends AuthEvent {
  const TokenRefreshRequested();
}
