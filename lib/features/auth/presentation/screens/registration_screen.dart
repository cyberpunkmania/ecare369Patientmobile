import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/theme_config.dart';
import '../../../../core/widgets/top_notification.dart';
import '../../domain/entities/patient_registration_entity.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';

/// Multi-step patient self-registration screen.
/// Breaks the registration process into 3 steps for better UX.
class RegistrationScreen extends StatefulWidget {
  /// Called when registration is successful - navigates to email lookup.
  final VoidCallback? onRegistrationSuccess;

  /// Called when user wants to go back to login.
  final VoidCallback? onBackToLogin;

  /// Tenant the patient is registering under. Chosen on the
  /// `TenantSelectPage` immediately before this screen.
  final String tenantId;

  /// Display name of the selected tenant — shown as a confirmation pill.
  final String? tenantName;

  const RegistrationScreen({
    super.key,
    required this.tenantId,
    this.tenantName,
    this.onRegistrationSuccess,
    this.onBackToLogin,
  });

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  static const int _totalSteps = 3;

  // Form keys for each step
  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();
  final _step3FormKey = GlobalKey<FormState>();

  // Text controllers
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Focus nodes
  final _firstNameFocus = FocusNode();
  final _middleNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  DateTime? _dateOfBirth;
  Gender _selectedGender = Gender.preferNotToSay;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameFocus.dispose();
    _middleNameFocus.dispose();
    _lastNameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    if (step >= 0 && step < _totalSteps) {
      _pageController.animateToPage(
        step,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep = step);
    }
  }

  void _nextStep() {
    // Validate current step before proceeding
    if (!_validateCurrentStep()) return;

    if (_currentStep < _totalSteps - 1) {
      _goToStep(_currentStep + 1);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    } else {
      widget.onBackToLogin?.call();
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (!_step1FormKey.currentState!.validate()) {
          TopNotification.show(
            context,
            'Please fill in all required fields',
            type: NotificationType.error,
          );
          return false;
        }
        if (_dateOfBirth == null) {
          TopNotification.show(
            context,
            'Please select your date of birth',
            type: NotificationType.error,
          );
          return false;
        }
        // Validate age
        final now = DateTime.now();
        final age =
            now.year -
            _dateOfBirth!.year -
            (now.month < _dateOfBirth!.month ||
                    (now.month == _dateOfBirth!.month &&
                        now.day < _dateOfBirth!.day)
                ? 1
                : 0);
        if (age < 18) {
          TopNotification.show(
            context,
            'You must be at least 18 years old to register',
            type: NotificationType.error,
          );
          return false;
        }
        return true;

      case 1:
        if (!_step2FormKey.currentState!.validate()) {
          TopNotification.show(
            context,
            'Please provide valid contact information',
            type: NotificationType.error,
          );
          return false;
        }
        return true;

      case 2:
        if (!_step3FormKey.currentState!.validate()) {
          TopNotification.show(
            context,
            'Please create a valid password',
            type: NotificationType.error,
          );
          return false;
        }
        if (!_agreedToTerms) {
          TopNotification.show(
            context,
            'Please agree to the Terms of Service',
            type: NotificationType.error,
          );
          return false;
        }
        return true;

      default:
        return true;
    }
  }

  void _onSubmit() {
    if (!_validateCurrentStep()) return;

    final request = PatientRegistrationRequest(
      tenantId: widget.tenantId,
      firstName: _firstNameController.text.trim(),
      middleName: _middleNameController.text.trim().isNotEmpty
          ? _middleNameController.text.trim()
          : null,
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      dateOfBirth: _dateOfBirth!,
      gender: _selectedGender,
      patientType: PatientType.patientUser,
      password: _passwordController.text,
    );

    context.read<AuthBloc>().add(
      PatientRegistrationRequested(request: request),
    );
  }

  Future<void> _selectDateOfBirth() async {
    final now = DateTime.now();
    final maxAllowedDate = DateTime(now.year - 18, now.month, now.day);
    final initialDate = _dateOfBirth ?? DateTime(now.year - 25);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(maxAllowedDate)
          ? maxAllowedDate
          : initialDate,
      firstDate: DateTime(1900),
      lastDate: maxAllowedDate,
      helpText: 'Select your date of birth (must be 18+)',
    );

    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with back button and progress
        _buildHeader(),

        // Step indicator
        _buildStepIndicator(),

        // Page content
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) => setState(() => _currentStep = index),
            children: [
              _buildStep1PersonalInfo(),
              _buildStep2ContactInfo(),
              _buildStep3Password(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 24, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _previousStep,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Account',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Step ${_currentStep + 1} of $_totalSteps',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(_totalSteps * 2 - 1, (index) {
          if (index.isOdd) {
            // Connector line
            final stepIndex = index ~/ 2;
            return Expanded(
              child: Container(
                height: 2,
                color: stepIndex < _currentStep
                    ? AppColors.primary
                    : AppColors.textHint,
              ),
            );
          } else {
            // Step circle
            final stepIndex = index ~/ 2;
            final isActive = stepIndex == _currentStep;
            final isCompleted = stepIndex < _currentStep;

            return Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? AppColors.primary
                    : isActive
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : AppColors.surface,
                border: Border.all(
                  color: isActive || isCompleted
                      ? AppColors.primary
                      : AppColors.textHint,
                  width: 2,
                ),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Text(
                        '${stepIndex + 1}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isActive
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
              ),
            );
          }
        }),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Step 1: Personal Information
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildStep1PersonalInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _step1FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Text(
              'Personal Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please provide your legal name as it appears on your ID.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            // First Name
            TextFormField(
              controller: _firstNameController,
              focusNode: _firstNameFocus,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _middleNameFocus.requestFocus(),
              decoration: const InputDecoration(
                labelText: 'First Name *',
                hintText: 'Enter your first name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'First name is required';
                }
                if (value.trim().length > 100) {
                  return 'First name must be 100 characters or less';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Middle Name (Optional)
            TextFormField(
              controller: _middleNameController,
              focusNode: _middleNameFocus,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _lastNameFocus.requestFocus(),
              decoration: const InputDecoration(
                labelText: 'Middle Name (Optional)',
                hintText: 'Enter your middle name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value != null && value.trim().length > 100) {
                  return 'Middle name must be 100 characters or less';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Last Name
            TextFormField(
              controller: _lastNameController,
              focusNode: _lastNameFocus,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _selectDateOfBirth(),
              decoration: const InputDecoration(
                labelText: 'Last Name *',
                hintText: 'Enter your last name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Last name is required';
                }
                if (value.trim().length > 100) {
                  return 'Last name must be 100 characters or less';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Date of Birth
            InkWell(
              onTap: _selectDateOfBirth,
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Date of Birth * (Must be 18+)',
                  prefixIcon: const Icon(Icons.calendar_today_outlined),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                  errorText: null,
                ),
                child: Text(
                  _dateOfBirth != null
                      ? DateFormat('MMMM d, yyyy').format(_dateOfBirth!)
                      : 'Select your date of birth',
                  style: TextStyle(
                    color: _dateOfBirth != null
                        ? AppColors.textPrimary
                        : AppColors.textHint,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Gender
            DropdownButtonFormField<Gender>(
              value: _selectedGender,
              decoration: const InputDecoration(
                labelText: 'Gender *',
                prefixIcon: Icon(Icons.wc_outlined),
              ),
              items: Gender.values.map((gender) {
                return DropdownMenuItem(
                  value: gender,
                  child: Text(_getGenderDisplayName(gender)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedGender = value);
                }
              },
            ),
            const SizedBox(height: 32),

            // Next button
            FilledButton(
              onPressed: _nextStep,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Continue'),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Back to login
            TextButton(
              onPressed: widget.onBackToLogin,
              child: const Text('Already have an account? Sign in'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Step 2: Contact Information
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildStep2ContactInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _step2FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Text(
              'Contact Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We\'ll use this to send you important health updates.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            // Email
            TextFormField(
              controller: _emailController,
              focusNode: _emailFocus,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              autofillHints: const [AutofillHints.email],
              onFieldSubmitted: (_) => _phoneFocus.requestFocus(),
              decoration: const InputDecoration(
                labelText: 'Email Address *',
                hintText: 'you@example.com',
                prefixIcon: Icon(Icons.email_outlined),
                helperText: 'You\'ll use this to sign in',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email address is required';
                }
                final emailRegex = RegExp(
                  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                );
                if (!emailRegex.hasMatch(value.trim())) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Phone Number
            TextFormField(
              controller: _phoneController,
              focusNode: _phoneFocus,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.telephoneNumber],
              onFieldSubmitted: (_) => _nextStep(),
              decoration: const InputDecoration(
                labelText: 'Phone Number *',
                hintText: '+254712345678',
                prefixIcon: Icon(Icons.phone_outlined),
                helperText: 'Include country code (e.g., +254)',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Phone number is required';
                }
                final phoneRegex = RegExp(r'^\+?\d{9,15}$');
                if (!phoneRegex.hasMatch(value.trim().replaceAll(' ', ''))) {
                  return 'Please enter a valid phone number (9-15 digits)';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Navigation buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _previousStep,
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text(''),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _nextStep,
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: const Text('Continue'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Step 3: Password & Terms
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildStep3Password() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _step3FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Text(
              'Create Password',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your password must be at least 8 characters and include uppercase, lowercase, number, and special character.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            // Password
            TextFormField(
              controller: _passwordController,
              focusNode: _passwordFocus,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              onFieldSubmitted: (_) => _confirmPasswordFocus.requestFocus(),
              decoration: InputDecoration(
                labelText: 'Password *',
                hintText: 'Create a strong password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required';
                }
                if (value.length < 8) {
                  return 'Password must be at least 8 characters';
                }
                if (!RegExp(r'[A-Z]').hasMatch(value)) {
                  return 'Password must contain an uppercase letter';
                }
                if (!RegExp(r'[a-z]').hasMatch(value)) {
                  return 'Password must contain a lowercase letter';
                }
                if (!RegExp(r'[0-9]').hasMatch(value)) {
                  return 'Password must contain a number';
                }
                if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
                  return 'Password must contain a special character';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Confirm Password
            TextFormField(
              controller: _confirmPasswordController,
              focusNode: _confirmPasswordFocus,
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _onSubmit(),
              decoration: InputDecoration(
                labelText: 'Confirm Password *',
                hintText: 'Re-enter your password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Terms Agreement
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.textHint),
              ),
              child: CheckboxListTile(
                value: _agreedToTerms,
                onChanged: (value) {
                  setState(() => _agreedToTerms = value ?? false);
                },
                controlAffinity: ListTileControlAffinity.leading,
                title: Text.rich(
                  TextSpan(
                    text: 'I agree to the ',
                    style: Theme.of(context).textTheme.bodySmall,
                    children: [
                      TextSpan(
                        text: 'Terms of Service',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Navigation buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _previousStep,
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text(''),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _onSubmit,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Create Account'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _getGenderDisplayName(Gender gender) {
    switch (gender) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
      case Gender.other:
        return 'Other';
      case Gender.preferNotToSay:
        return 'Prefer not to say';
    }
  }
}
