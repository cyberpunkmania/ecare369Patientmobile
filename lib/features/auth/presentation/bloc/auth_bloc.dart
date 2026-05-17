import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/account_option_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth_usecases.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// AuthBloc manages the multi-flow authentication state machine.
///
/// Supports three authentication flows:
/// - Flow A (Active): Email → Password → OTP → Authenticated
/// - Flow B (Onboarding): Email → Security Setup → OTP → Authenticated
/// - Flow C (Inactive): Email → Security Q&A → New Password → Authenticated
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  // ══════════════════════════════════════════════════════════════════════════
  // ── Use Cases ──
  // ══════════════════════════════════════════════════════════════════════════
  final RegisterPatientUseCase _registerPatientUseCase;
  final LookupEmailUseCase _lookupEmailUseCase;
  final GenerateLoginOtpUseCase _generateLoginOtpUseCase;
  final VerifyLoginOtpUseCase _verifyLoginOtpUseCase;
  final GetSecurityQuestionsUseCase _getSecurityQuestionsUseCase;
  final SetupAccountUseCase _setupAccountUseCase;
  final ConfirmOnboardingUseCase _confirmOnboardingUseCase;
  final FetchUserSecurityQuestionsUseCase _fetchUserSecurityQuestionsUseCase;
  final ActivateExistingUserUseCase _activateExistingUserUseCase;
  final LogoutUseCase _logoutUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final RefreshTokenUseCase _refreshTokenUseCase;
  final AuthRepository _authRepository;

  // ══════════════════════════════════════════════════════════════════════════
  // ── Flow Context ──
  // ══════════════════════════════════════════════════════════════════════════
  /// Stores the current email being processed across flow states.
  String? _currentEmail;

  /// Stores the selected account for the current flow.
  AccountOptionEntity? _selectedAccount;

  /// Stores the password temporarily for OTP resend.
  String? _currentPassword;

  /// Pool of security questions for onboarding (grows via background fetches).
  List<String> _questionPool = [];

  /// Password captured during self-registration to pre-fill account setup.
  String? _registrationPassword;

  AuthBloc({
    required RegisterPatientUseCase registerPatientUseCase,
    required LookupEmailUseCase lookupEmailUseCase,
    required GenerateLoginOtpUseCase generateLoginOtpUseCase,
    required VerifyLoginOtpUseCase verifyLoginOtpUseCase,
    required GetSecurityQuestionsUseCase getSecurityQuestionsUseCase,
    required SetupAccountUseCase setupAccountUseCase,
    required ConfirmOnboardingUseCase confirmOnboardingUseCase,
    required FetchUserSecurityQuestionsUseCase
    fetchUserSecurityQuestionsUseCase,
    required ActivateExistingUserUseCase activateExistingUserUseCase,
    required LogoutUseCase logoutUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
    required RefreshTokenUseCase refreshTokenUseCase,
    required AuthRepository authRepository,
  }) : _registerPatientUseCase = registerPatientUseCase,
       _lookupEmailUseCase = lookupEmailUseCase,
       _generateLoginOtpUseCase = generateLoginOtpUseCase,
       _verifyLoginOtpUseCase = verifyLoginOtpUseCase,
       _getSecurityQuestionsUseCase = getSecurityQuestionsUseCase,
       _setupAccountUseCase = setupAccountUseCase,
       _confirmOnboardingUseCase = confirmOnboardingUseCase,
       _fetchUserSecurityQuestionsUseCase = fetchUserSecurityQuestionsUseCase,
       _activateExistingUserUseCase = activateExistingUserUseCase,
       _logoutUseCase = logoutUseCase,
       _getCurrentUserUseCase = getCurrentUserUseCase,
       _refreshTokenUseCase = refreshTokenUseCase,
       _authRepository = authRepository,
       super(AuthInitial()) {
    // Session management
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthResetRequested>(_onResetRequested);
    on<AuthBackRequested>(_onBackRequested);

    // Patient registration (self-onboarding)
    on<PatientRegistrationRequested>(_onPatientRegistrationRequested);

    // Email lookup
    on<LookupEmailRequested>(_onLookupEmailRequested);
    on<AccountSelected>(_onAccountSelected);

    // Flow A: Active user login
    on<PasswordSubmitted>(_onPasswordSubmitted);
    on<OtpSubmitted>(_onOtpSubmitted);
    on<ResendOtpRequested>(_onResendOtpRequested);

    // Flow B: Onboarding
    on<FetchSecurityQuestionsRequested>(_onFetchSecurityQuestionsRequested);
    on<FetchMoreSecurityQuestionsRequested>(_onFetchMoreSecurityQuestions);
    on<AccountSetupSubmitted>(_onAccountSetupSubmitted);

    // Flow C: Reactivation
    on<FetchUserSecurityQuestionsRequested>(
      _onFetchUserSecurityQuestionsRequested,
    );
    on<ReactivationSubmitted>(_onReactivationSubmitted);

    // Token management
    on<TokenRefreshRequested>(_onTokenRefreshRequested);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Patient Registration Handler ──
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _onPatientRegistrationRequested(
    PatientRegistrationRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Creating your account...'));

    final result = await _registerPatientUseCase(request: event.request);
    result.fold(
      (failure) => emit(
        AuthError(
          message: failure.message,
          previousState: AuthUnauthenticated(),
        ),
      ),
      (patient) {
        // Store email and registration password for subsequent account setup
        _currentEmail = patient.email;
        _registrationPassword = event.request.password;
        emit(
          PatientRegistrationSuccess(
            patient: patient,
            message:
                'Account created successfully! Please proceed to set up your password.',
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Session Management Handlers ──
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Checking session...'));

    final isLoggedIn = await _authRepository.isLoggedIn();
    if (!isLoggedIn) {
      emit(AuthUnauthenticated());
      return;
    }

    // Check if token is expired
    final isExpired = await _authRepository.isTokenExpired();
    if (isExpired) {
      // Try to refresh the token
      final refreshResult = await _refreshTokenUseCase();
      final shouldProceed = refreshResult.fold((failure) {
        // Refresh failed, user needs to re-authenticate
        emit(AuthUnauthenticated());
        return false;
      }, (tokenRefresh) => true);
      if (!shouldProceed) return;
    }

    // Get cached user
    final result = await _getCurrentUserUseCase();
    result.fold(
      (failure) => emit(AuthUnauthenticated()),
      (user) => emit(AuthAuthenticated(user: user)),
    );
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Logging out...'));
    await _logoutUseCase();
    _clearFlowContext();
    emit(AuthUnauthenticated());
  }

  void _onResetRequested(AuthResetRequested event, Emitter<AuthState> emit) {
    _clearFlowContext();
    emit(AuthUnauthenticated());
  }

  void _onBackRequested(AuthBackRequested event, Emitter<AuthState> emit) {
    final currentState = state;

    // Navigate back based on current state
    if (currentState is PasswordRequired ||
        currentState is OnboardingSecurityQuestionsLoaded ||
        currentState is ReactivationSecurityQuestionsLoaded) {
      // Go back to email lookup / account selection
      if (_currentEmail != null) {
        add(LookupEmailRequested(email: _currentEmail!));
      } else {
        emit(AuthUnauthenticated());
      }
    } else if (currentState is OtpVerificationRequired) {
      // Go back to password (Flow A) or setup (Flow B)
      if (_selectedAccount != null) {
        add(AccountSelected(account: _selectedAccount!));
      }
    } else if (currentState is LookupSuccess) {
      // Go back to email entry
      _clearFlowContext();
      emit(AuthUnauthenticated());
    } else {
      emit(AuthUnauthenticated());
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Email Lookup Handlers ──
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _onLookupEmailRequested(
    LookupEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Looking up account...'));

    _currentEmail = event.email;

    final result = await _lookupEmailUseCase(email: event.email);
    result.fold(
      (failure) => emit(
        AuthError(
          message: failure.message,
          previousState: AuthUnauthenticated(),
        ),
      ),
      (lookupResult) {
        final state = LookupSuccess(
          email: event.email,
          lookupResult: lookupResult,
        );

        // Auto-select if only one account
        if (!state.requiresAccountSelection && state.allAccounts.isNotEmpty) {
          emit(state);
          add(AccountSelected(account: state.allAccounts.first));
        } else if (state.allAccounts.isEmpty) {
          emit(
            AuthError(
              message: 'No accounts found for this email',
              previousState: AuthUnauthenticated(),
            ),
          );
        } else {
          emit(state);
        }
      },
    );
  }

  Future<void> _onAccountSelected(
    AccountSelected event,
    Emitter<AuthState> emit,
  ) async {
    _selectedAccount = event.account;

    // Persist tenant ID now so auth_interceptor sends X-Tenant-ID on every
    // subsequent request (generate-login-otp, setup-account, etc.).
    if (event.account.tenantId != null && event.account.tenantId!.isNotEmpty) {
      await _authRepository.saveAccountContext(
        tenantId: event.account.tenantId!,
        branchId: event.account.branchId,
      );
    }

    // Determine flow based on account status
    switch (event.account.status) {
      case AccountStatus.active:
        // Flow A: Show password screen
        emit(
          PasswordRequired(
            email: _currentEmail!,
            selectedAccount: event.account,
          ),
        );
        break;

      case AccountStatus.onboarding:
        // Flow B: Fetch security questions and show setup screen
        emit(const AuthLoading(message: 'Loading security questions...'));
        add(const FetchSecurityQuestionsRequested());
        break;

      case AccountStatus.inactive:
        // Flow C: Fetch user's security questions
        emit(const AuthLoading(message: 'Loading your security questions...'));
        add(const FetchUserSecurityQuestionsRequested());
        break;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Flow A: Active User Login Handlers ──
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _onPasswordSubmitted(
    PasswordSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    if (_currentEmail == null || _selectedAccount == null) {
      emit(
        AuthError(
          message: 'Session expired. Please start over.',
          previousState: AuthUnauthenticated(),
        ),
      );
      return;
    }

    emit(const AuthLoading(message: 'Verifying password...'));
    _currentPassword = event.password;

    final result = await _generateLoginOtpUseCase(
      email: _currentEmail!,
      userId: _selectedAccount!.userId ?? '',
      password: event.password,
    );

    result.fold(
      (failure) => emit(
        AuthError(
          message: failure.message,
          previousState: PasswordRequired(
            email: _currentEmail!,
            selectedAccount: _selectedAccount!,
          ),
        ),
      ),
      (otpResponse) => emit(
        OtpVerificationRequired(
          email: _currentEmail!,
          selectedAccount: _selectedAccount!,
          otpResponse: otpResponse,
          flow: AuthFlow.activeLogin,
        ),
      ),
    );
  }

  Future<void> _onOtpSubmitted(
    OtpSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    // Unwrap the actual OTP state: it may be wrapped inside AuthError or
    // AuthLoading from a prior attempt (e.g. double-submit race).
    AuthState raw = state;
    if (raw is AuthError && raw.previousState is OtpVerificationRequired) {
      raw = raw.previousState!;
    }
    if (raw is AuthLoading) {
      return; // already processing — ignore duplicate
    }
    final currentState = raw;
    if (currentState is! OtpVerificationRequired) {
      return; // silently ignore — don't navigate away
    }

    emit(const AuthLoading(message: 'Verifying OTP...'));

    if (currentState.flow == AuthFlow.activeLogin) {
      // Flow A: Verify login OTP — use userId from the OTP response (authoritative)
      final result = await _verifyLoginOtpUseCase(
        userId: currentState.otpResponse.userId,
        otpCode: event.otp,
      );

      result.fold(
        (failure) => emit(
          AuthError(message: failure.message, previousState: currentState),
        ),
        (auth) {
          _clearFlowContext();
          emit(AuthAuthenticated(user: auth.user));
        },
      );
    } else if (currentState.flow == AuthFlow.onboarding) {
      // Flow B: Confirm onboarding OTP — use userId from setup-account response
      // (selectedAccount.userId may be null for self-registered orphan patients)
      final result = await _confirmOnboardingUseCase(
        email: currentState.email,
        userId: currentState.otpResponse.userId,
        otpCode: event.otp,
        patientId: currentState.selectedAccount.patientId,
      );

      result.fold(
        (failure) => emit(
          AuthError(message: failure.message, previousState: currentState),
        ),
        (auth) {
          _clearFlowContext();
          emit(AuthAuthenticated(user: auth.user));
        },
      );
    }
  }

  Future<void> _onResendOtpRequested(
    ResendOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is! OtpVerificationRequired) return;

    emit(const AuthLoading(message: 'Resending OTP...'));

    if (currentState.flow == AuthFlow.activeLogin && _currentPassword != null) {
      // Resend for Flow A
      final result = await _generateLoginOtpUseCase(
        email: currentState.email,
        userId: currentState.selectedAccount.userId ?? '',
        password: _currentPassword!,
      );

      result.fold(
        (failure) => emit(
          AuthError(message: failure.message, previousState: currentState),
        ),
        (otpResponse) => emit(
          OtpVerificationRequired(
            email: currentState.email,
            selectedAccount: currentState.selectedAccount,
            otpResponse: otpResponse,
            flow: AuthFlow.activeLogin,
          ),
        ),
      );
    } else {
      // For onboarding, they need to re-submit the setup form
      emit(
        AuthError(
          message: 'Please complete the setup form again to resend OTP',
          previousState: currentState,
        ),
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Flow B: Onboarding Handlers ──
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _onFetchSecurityQuestionsRequested(
    FetchSecurityQuestionsRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (_currentEmail == null || _selectedAccount == null) {
      emit(
        AuthError(
          message: 'Session expired. Please start over.',
          previousState: AuthUnauthenticated(),
        ),
      );
      return;
    }

    final result = await _getSecurityQuestionsUseCase();
    result.fold(
      (failure) => emit(
        AuthError(
          message: failure.message,
          previousState: AuthUnauthenticated(),
        ),
      ),
      (questions) {
        _questionPool = List.of(questions);
        final password = _registrationPassword;
        _registrationPassword = null; // consume it — one-time use
        emit(
          OnboardingSecurityQuestionsLoaded(
            email: _currentEmail!,
            selectedAccount: _selectedAccount!,
            questions: List.unmodifiable(_questionPool),
            prefillPassword: password,
          ),
        );
      },
    );
  }

  Future<void> _onFetchMoreSecurityQuestions(
    FetchMoreSecurityQuestionsRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _getSecurityQuestionsUseCase();
    result.fold((_) {}, (questions) {
      for (final q in questions) {
        if (!_questionPool.contains(q)) _questionPool.add(q);
      }
      if (state is OnboardingSecurityQuestionsLoaded) {
        final currentState = state as OnboardingSecurityQuestionsLoaded;
        emit(
          OnboardingSecurityQuestionsLoaded(
            email: _currentEmail!,
            selectedAccount: _selectedAccount!,
            questions: List.unmodifiable(_questionPool),
            prefillPassword:
                currentState.prefillPassword, // preserve through pool refresh
          ),
        );
      }
    });
  }

  Future<void> _onAccountSetupSubmitted(
    AccountSetupSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is! OnboardingSecurityQuestionsLoaded) {
      emit(
        AuthError(
          message: 'Invalid state for account setup',
          previousState: AuthUnauthenticated(),
        ),
      );
      return;
    }

    emit(const AuthLoading(message: 'Setting up your account...'));

    final result = await _setupAccountUseCase(
      email: currentState.email,
      userId: currentState.selectedAccount.userId,
      password: event.password,
      confirmPassword: event.password,
      securityQuestions: event.securityQuestions,
      patientId: currentState.selectedAccount.patientId,
      tenantId: currentState.selectedAccount.tenantId,
    );

    result.fold(
      (failure) => emit(
        AuthError(message: failure.message, previousState: currentState),
      ),
      (otpResponse) => emit(
        OtpVerificationRequired(
          email: currentState.email,
          selectedAccount: currentState.selectedAccount,
          otpResponse: otpResponse,
          flow: AuthFlow.onboarding,
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Flow C: Reactivation Handlers ──
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _onFetchUserSecurityQuestionsRequested(
    FetchUserSecurityQuestionsRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (_currentEmail == null || _selectedAccount == null) {
      emit(
        AuthError(
          message: 'Session expired. Please start over.',
          previousState: AuthUnauthenticated(),
        ),
      );
      return;
    }

    final result = await _fetchUserSecurityQuestionsUseCase(
      email: _currentEmail!,
      tenantId: _selectedAccount!.tenantId ?? '',
    );

    result.fold(
      (failure) => emit(
        AuthError(
          message: failure.message,
          previousState: AuthUnauthenticated(),
        ),
      ),
      (userQuestions) => emit(
        ReactivationSecurityQuestionsLoaded(
          email: _currentEmail!,
          selectedAccount: _selectedAccount!,
          userQuestions: userQuestions,
        ),
      ),
    );
  }

  Future<void> _onReactivationSubmitted(
    ReactivationSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ReactivationSecurityQuestionsLoaded) {
      emit(
        AuthError(
          message: 'Invalid state for reactivation',
          previousState: AuthUnauthenticated(),
        ),
      );
      return;
    }

    emit(const AuthLoading(message: 'Reactivating your account...'));

    final result = await _activateExistingUserUseCase(
      email: currentState.email,
      tenantId: currentState.selectedAccount.tenantId ?? '',
      newPassword: event.newPassword,
      securityAnswers: event.securityAnswers,
    );

    result.fold(
      (failure) => emit(
        AuthError(message: failure.message, previousState: currentState),
      ),
      (auth) {
        _clearFlowContext();
        emit(AuthAuthenticated(user: auth.user));
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Token Management Handlers ──
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _onTokenRefreshRequested(
    TokenRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _refreshTokenUseCase();
    result.fold(
      (failure) {
        // Token refresh failed, force logout
        add(const AuthLogoutRequested());
      },
      (tokenRefresh) {
        // Token refreshed silently, no state change needed
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Private Helpers ──
  // ══════════════════════════════════════════════════════════════════════════

  void _clearFlowContext() {
    _currentEmail = null;
    _selectedAccount = null;
    _currentPassword = null;
    _registrationPassword = null;
    _questionPool.clear();
  }
}
