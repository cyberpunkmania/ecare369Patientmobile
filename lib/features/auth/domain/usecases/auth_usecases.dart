/// Auth usecases barrel file.
///
/// Exports all authentication-related use cases for the multi-flow auth system.

// ══════════════════════════════════════════════════════════════════════════
// ── Patient Registration ──
// ══════════════════════════════════════════════════════════════════════════
export 'register_patient_usecase.dart';

// ══════════════════════════════════════════════════════════════════════════
// ── Common ──
// ══════════════════════════════════════════════════════════════════════════
export 'lookup_email_usecase.dart';
export 'logout_usecase.dart';
export 'get_current_user_usecase.dart';
export 'refresh_token_usecase.dart';

// ══════════════════════════════════════════════════════════════════════════
// ── Flow A: Active User Login ──
// ══════════════════════════════════════════════════════════════════════════
export 'generate_login_otp_usecase.dart';
export 'verify_login_otp_usecase.dart';

// ══════════════════════════════════════════════════════════════════════════
// ── Flow B: New Account Onboarding ──
// ══════════════════════════════════════════════════════════════════════════
export 'get_security_questions_usecase.dart';
export 'setup_account_usecase.dart';
export 'confirm_onboarding_usecase.dart';

// ══════════════════════════════════════════════════════════════════════════
// ── Flow C: Inactive Account Reactivation ──
// ══════════════════════════════════════════════════════════════════════════
export 'fetch_user_security_questions_usecase.dart';
export 'activate_existing_user_usecase.dart';
