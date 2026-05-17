import 'package:equatable/equatable.dart';

import '../../domain/entities/account_option_entity.dart';
import '../../domain/entities/lookup_result_entity.dart';
import '../../domain/entities/otp_response_entity.dart';
import '../../domain/entities/patient_registration_entity.dart';
import '../../domain/entities/security_question_entity.dart';
import '../../domain/entities/user_entity.dart';

/// Base class for all auth states.
///
/// The auth flow state machine supports:
/// - Registration: Patient self-registration with password
/// - Flow A (Active): Email → Account Picker → Password → OTP → Authenticated
/// - Flow B (Onboarding): Email → Account Picker → Setup → OTP → Authenticated
/// - Flow C (Inactive): Email → Account Picker → Security Q&A → Authenticated
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

// ══════════════════════════════════════════════════════════════════════════
// ── Initial & Common States ──
// ══════════════════════════════════════════════════════════════════════════

/// Initial state before any auth check.
class AuthInitial extends AuthState {}

/// Loading state for any async operation.
class AuthLoading extends AuthState {
  final String? message;
  const AuthLoading({this.message});

  @override
  List<Object?> get props => [message];
}

/// User is not authenticated - show email entry screen.
class AuthUnauthenticated extends AuthState {}

/// User successfully authenticated - proceed to app.
class AuthAuthenticated extends AuthState {
  final UserEntity user;
  const AuthAuthenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

/// Auth error occurred - can retry from current step.
class AuthError extends AuthState {
  final String message;
  final AuthState? previousState;

  const AuthError({required this.message, this.previousState});

  @override
  List<Object?> get props => [message, previousState];
}

// ══════════════════════════════════════════════════════════════════════════
// ── Registration States ──
// ══════════════════════════════════════════════════════════════════════════

/// Patient registration successful - navigate to login screen.
class PatientRegistrationSuccess extends AuthState {
  final PatientEntity patient;
  final String message;

  const PatientRegistrationSuccess({
    required this.patient,
    this.message = 'Patient registered successfully. Please verify your email.',
  });

  @override
  List<Object?> get props => [patient, message];
}

// ══════════════════════════════════════════════════════════════════════════
// ── Email Lookup States ──
// ══════════════════════════════════════════════════════════════════════════

/// Email lookup successful - show account picker if multiple accounts,
/// or proceed to next step based on account status.
class LookupSuccess extends AuthState {
  final String email;
  final LookupResultEntity lookupResult;

  const LookupSuccess({required this.email, required this.lookupResult});

  /// All accounts across all categories.
  List<AccountOptionEntity> get allAccounts => [
    ...lookupResult.canLoginAccounts,
    ...lookupResult.onboardingAccounts,
    ...lookupResult.inactiveAccounts,
  ];

  /// True if user needs to pick from multiple accounts.
  bool get requiresAccountSelection => allAccounts.length > 1;

  @override
  List<Object?> get props => [email, lookupResult];
}

// ══════════════════════════════════════════════════════════════════════════
// ── Flow A: Active User Login States ──
// ══════════════════════════════════════════════════════════════════════════

/// Flow A Step 2: Password entry required for active account.
class PasswordRequired extends AuthState {
  final String email;
  final AccountOptionEntity selectedAccount;

  const PasswordRequired({required this.email, required this.selectedAccount});

  @override
  List<Object?> get props => [email, selectedAccount];
}

/// Flow A Step 3 / Flow B Step 3: OTP verification required.
class OtpVerificationRequired extends AuthState {
  final String email;
  final AccountOptionEntity selectedAccount;
  final OtpResponseEntity otpResponse;
  final AuthFlow flow;

  const OtpVerificationRequired({
    required this.email,
    required this.selectedAccount,
    required this.otpResponse,
    required this.flow,
  });

  @override
  List<Object?> get props => [email, selectedAccount, otpResponse, flow];
}

// ══════════════════════════════════════════════════════════════════════════
// ── Flow B: Onboarding States ──
// ══════════════════════════════════════════════════════════════════════════

/// Flow B Step 1: Security questions loaded for new account setup.
class OnboardingSecurityQuestionsLoaded extends AuthState {
  final String email;
  final AccountOptionEntity selectedAccount;
  final List<String> questions;

  /// Password carried forward from self-registration (step 3).
  /// When set, AccountSetupScreen skips the password phase.
  final String? prefillPassword;

  const OnboardingSecurityQuestionsLoaded({
    required this.email,
    required this.selectedAccount,
    required this.questions,
    this.prefillPassword,
  });

  @override
  List<Object?> get props => [
    email,
    selectedAccount,
    questions,
    prefillPassword,
  ];
}

// ══════════════════════════════════════════════════════════════════════════
// ── Flow C: Reactivation States ──
// ══════════════════════════════════════════════════════════════════════════

/// Flow C Step 1: User's security questions loaded for reactivation.
class ReactivationSecurityQuestionsLoaded extends AuthState {
  final String email;
  final AccountOptionEntity selectedAccount;
  final UserSecurityQuestionsEntity userQuestions;

  const ReactivationSecurityQuestionsLoaded({
    required this.email,
    required this.selectedAccount,
    required this.userQuestions,
  });

  @override
  List<Object?> get props => [email, selectedAccount, userQuestions];
}

// ══════════════════════════════════════════════════════════════════════════
// ── Helper Extension ──
// ══════════════════════════════════════════════════════════════════════════

/// Extension to provide context data from any state.
extension AuthStateContext on AuthState {
  /// Get the current email if available in this state.
  String? get currentEmail {
    if (this is LookupSuccess) return (this as LookupSuccess).email;
    if (this is PasswordRequired) return (this as PasswordRequired).email;
    if (this is OtpVerificationRequired)
      return (this as OtpVerificationRequired).email;
    if (this is OnboardingSecurityQuestionsLoaded) {
      return (this as OnboardingSecurityQuestionsLoaded).email;
    }
    if (this is ReactivationSecurityQuestionsLoaded) {
      return (this as ReactivationSecurityQuestionsLoaded).email;
    }
    return null;
  }

  /// Get the selected account if available in this state.
  AccountOptionEntity? get currentAccount {
    if (this is PasswordRequired)
      return (this as PasswordRequired).selectedAccount;
    if (this is OtpVerificationRequired) {
      return (this as OtpVerificationRequired).selectedAccount;
    }
    if (this is OnboardingSecurityQuestionsLoaded) {
      return (this as OnboardingSecurityQuestionsLoaded).selectedAccount;
    }
    if (this is ReactivationSecurityQuestionsLoaded) {
      return (this as ReactivationSecurityQuestionsLoaded).selectedAccount;
    }
    return null;
  }
}
