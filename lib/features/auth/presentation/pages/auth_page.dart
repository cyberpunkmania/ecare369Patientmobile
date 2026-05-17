import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/theme_config.dart';
import '../../../../routes/app_router.dart';
import '../../../tenants/domain/entities/public_tenant_entity.dart';
import '../../../tenants/presentation/pages/tenant_select_page.dart';
import '../../domain/entities/account_option_entity.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../screens/email_entry_screen.dart';
import '../screens/account_picker_screen.dart';
import '../screens/password_entry_screen.dart';
import '../screens/otp_verification_screen.dart';
import '../screens/account_setup_screen.dart';
import '../screens/reactivation_screen.dart';
import '../screens/registration_screen.dart';

/// Main authentication page that orchestrates all auth flows.
/// Listens to AuthBloc state and displays the appropriate screen.
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  /// Whether to show registration screen instead of login.
  bool _showRegistration = false;

  /// Tenant chosen on the TenantSelectPage — required before registration.
  PublicTenantEntity? _selectedTenant;

  Future<void> _switchToRegistration() async {
    final tenant = await Navigator.of(context).push<PublicTenantEntity>(
      MaterialPageRoute(builder: (_) => const TenantSelectPage()),
    );
    if (!mounted || tenant == null) return;
    setState(() {
      _selectedTenant = tenant;
      _showRegistration = true;
    });
  }

  void _switchToLogin() {
    setState(() => _showRegistration = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: _handleStateChanges,
          builder: (context, state) {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildScreen(context, state),
            );
          },
        ),
      ),
    );
  }

  void _handleStateChanges(BuildContext context, AuthState state) {
    // Handle error states
    if (state is AuthError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }

    // Handle successful registration
    if (state is PatientRegistrationSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      // Auto-trigger email lookup to proceed to account setup
      _switchToLogin();
      context.read<AuthBloc>().add(
        LookupEmailRequested(email: state.patient.email),
      );
    }

    // Handle successful authentication
    if (state is AuthAuthenticated) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        Routes.dashboard,
        (_) => false,
      );
    }
  }

  Widget _buildScreen(BuildContext context, AuthState state) {
    // Show registration screen if flag is set and not in middle of auth flow
    if (_showRegistration && _canShowRegistration(state)) {
      final tenant = _selectedTenant;
      if (tenant == null) {
        // Safety net — a tenant must be selected before this screen.
        return _EmailEntryWithRegistration(
          key: const ValueKey('email_no_tenant'),
          onRegisterPressed: _switchToRegistration,
        );
      }
      return RegistrationScreen(
        key: ValueKey('registration_${tenant.id}'),
        tenantId: tenant.id,
        tenantName: tenant.name,
        onRegistrationSuccess: _switchToLogin,
        onBackToLogin: _switchToLogin,
      );
    }

    return switch (state) {
      // ────────────────────────────────────────────────────────────────────
      // INITIAL / LOADING / UNAUTHENTICATED
      // ────────────────────────────────────────────────────────────────────
      AuthInitial() => _EmailEntryWithRegistration(
        key: const ValueKey('email'),
        onRegisterPressed: _switchToRegistration,
      ),

      AuthUnauthenticated() => _EmailEntryWithRegistration(
        key: const ValueKey('email'),
        onRegisterPressed: _switchToRegistration,
      ),

      AuthLoading(:final message) => _LoadingScreen(
        key: const ValueKey('loading'),
        message: message,
      ),

      // ────────────────────────────────────────────────────────────────────
      // REGISTRATION SUCCESS - Transitions to lookup automatically
      // ────────────────────────────────────────────────────────────────────
      PatientRegistrationSuccess() => _LoadingScreen(
        key: const ValueKey('registration_success'),
        message: 'Account created! Setting up...',
      ),

      // ────────────────────────────────────────────────────────────────────
      // ERROR STATE - Shows previous screen with error already shown via snackbar
      // ────────────────────────────────────────────────────────────────────
      AuthError(:final previousState) =>
        previousState != null
            ? _buildScreen(context, previousState)
            : _EmailEntryWithRegistration(
                key: const ValueKey('email_error'),
                onRegisterPressed: _switchToRegistration,
              ),

      // ────────────────────────────────────────────────────────────────────
      // LOOKUP SUCCESS - Show account picker
      // ────────────────────────────────────────────────────────────────────
      LookupSuccess(:final email, :final lookupResult) => AccountPickerScreen(
        key: const ValueKey('account_picker'),
        email: email,
        lookupResult: lookupResult,
      ),

      // ────────────────────────────────────────────────────────────────────
      // FLOW A: ACTIVE USER LOGIN
      // ────────────────────────────────────────────────────────────────────
      PasswordRequired(:final email, :final selectedAccount) =>
        PasswordEntryScreen(
          key: const ValueKey('password'),
          email: email,
          account: selectedAccount,
        ),

      OtpVerificationRequired(:final otpResponse, :final flow) =>
        OtpVerificationScreen(
          key: const ValueKey('otp'),
          maskedEmail: otpResponse.maskedEmail,
          otpExpiresAt: otpResponse.otpExpiresAt,
          flowContext: flow == AuthFlow.onboarding ? 'onboarding' : 'login',
        ),

      // ────────────────────────────────────────────────────────────────────
      // FLOW B: ONBOARDING
      // ────────────────────────────────────────────────────────────────────
      OnboardingSecurityQuestionsLoaded(
        :final email,
        :final selectedAccount,
        :final questions,
        :final prefillPassword,
      ) =>
        AccountSetupScreen(
          key: const ValueKey('account_setup'),
          email: email,
          account: selectedAccount,
          securityQuestions: questions,
          prefillPassword: prefillPassword,
        ),

      // ────────────────────────────────────────────────────────────────────
      // FLOW C: REACTIVATION
      // ────────────────────────────────────────────────────────────────────
      ReactivationSecurityQuestionsLoaded(
        :final email,
        :final selectedAccount,
        :final userQuestions,
      ) =>
        ReactivationScreen(
          key: const ValueKey('reactivation'),
          email: email,
          account: selectedAccount,
          userSecurityQuestions: userQuestions,
        ),

      // ────────────────────────────────────────────────────────────────────
      // AUTHENTICATED - Should not be visible (router will redirect)
      // ────────────────────────────────────────────────────────────────────
      AuthAuthenticated() => _LoadingScreen(
        key: const ValueKey('authenticated'),
        message: 'Redirecting...',
      ),

      // ────────────────────────────────────────────────────────────────────
      // FALLBACK
      // ────────────────────────────────────────────────────────────────────
      _ => _EmailEntryWithRegistration(
        key: const ValueKey('email_fallback'),
        onRegisterPressed: _switchToRegistration,
      ),
    };
  }

  /// Determines if registration screen can be shown based on current state.
  bool _canShowRegistration(AuthState state) {
    return state is AuthInitial ||
        state is AuthUnauthenticated ||
        state is AuthError;
  }
}

/// Email entry screen wrapped with registration link.
class _EmailEntryWithRegistration extends StatelessWidget {
  final VoidCallback onRegisterPressed;

  const _EmailEntryWithRegistration({
    super.key,
    required this.onRegisterPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Expanded(child: EmailEntryScreen()),
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: TextButton(
            onPressed: onRegisterPressed,
            child: const Text("Don't have an account? Register"),
            // Don't have an account? Register
          ),
        ),
      ],
    );
  }
}

/// Loading screen with centered spinner and optional message.
class _LoadingScreen extends StatelessWidget {
  final String? message;

  const _LoadingScreen({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
