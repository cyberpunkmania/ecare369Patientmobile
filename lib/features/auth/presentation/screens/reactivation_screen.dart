import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/theme_config.dart';
import '../../domain/entities/account_option_entity.dart';
import '../../domain/entities/security_question_entity.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';

/// Reactivation screen for inactive accounts (Flow C).
/// User must answer their security questions and set a new password.
class ReactivationScreen extends StatefulWidget {
  final String email;
  final AccountOptionEntity account;
  final UserSecurityQuestionsEntity userSecurityQuestions;

  const ReactivationScreen({
    super.key,
    required this.email,
    required this.account,
    required this.userSecurityQuestions,
  });

  @override
  State<ReactivationScreen> createState() => _ReactivationScreenState();
}

class _ReactivationScreenState extends State<ReactivationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Answers for each security question (keyed by questionId)
  final Map<String, TextEditingController> _answerControllers = {};

  @override
  void initState() {
    super.initState();
    // Initialize a controller for each question
    for (final question in widget.userSecurityQuestions.questions) {
      if (question.questionId != null) {
        _answerControllers[question.questionId!] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    for (final controller in _answerControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final answers = widget.userSecurityQuestions.questions
        .where((q) => q.questionId != null)
        .map((q) {
          return SecurityQuestionAnswer(
            questionId: q.questionId,
            answer: _answerControllers[q.questionId]!.text.trim(),
          );
        })
        .toList();

    context.read<AuthBloc>().add(
      ReactivationSubmitted(
        newPassword: _passwordController.text,
        securityAnswers: answers,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),

            // ── Back Button ──
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  context.read<AuthBloc>().add(const AuthBackRequested());
                },
              ),
            ),
            const SizedBox(height: 16),

            // ── Warning Banner ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_outlined,
                    color: AppColors.warning,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account Reactivation',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.warning,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your account has been deactivated. Verify your identity to reactivate.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Account Info ──
            Card(
              color: AppColors.textSecondary.withValues(alpha: 0.05),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.textSecondary.withValues(
                        alpha: 0.1,
                      ),
                      child: const Icon(
                        Icons.person_off_outlined,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.email,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            widget.account.displayName,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ═══════════════════════════════════════════════════════════════
            // SECURITY QUESTIONS SECTION
            // ═══════════════════════════════════════════════════════════════
            Text(
              'Answer Security Questions',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Provide the answers you set when creating your account.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),

            // ── Security Questions ──
            ...widget.userSecurityQuestions.questions.asMap().entries.map((
              entry,
            ) {
              final index = entry.key;
              final question = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Question ${index + 1}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      question.question,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _answerControllers[question.questionId],
                      decoration: InputDecoration(
                        labelText: 'Your Answer',
                        prefixIcon: const Icon(Icons.edit_outlined),
                        helperText: 'Answer is case-insensitive',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please provide your answer';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),

            // ═══════════════════════════════════════════════════════════════
            // NEW PASSWORD SECTION
            // ═══════════════════════════════════════════════════════════════
            Text(
              'Create New Password',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Set a new password for your reactivated account.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),

            // ── Password Field ──
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'New Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a password';
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
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // ── Confirm Password Field ──
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () {
                    setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    );
                  },
                ),
              ),
              validator: (value) {
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),

            // ── Password Requirements ──
            _PasswordRequirements(password: _passwordController.text),

            const SizedBox(height: 32),

            // ── Submit Button ──
            FilledButton(
              onPressed: _onSubmit,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text('Reactivate Account'),
              ),
            ),
            const SizedBox(height: 16),

            // ── Help Text ──
            Center(
              child: TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Contact support if you cannot remember your security answers.',
                      ),
                    ),
                  );
                },
                child: const Text("Can't remember your answers?"),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Widget to display password requirements with visual indicators.
class _PasswordRequirements extends StatelessWidget {
  final String password;

  const _PasswordRequirements({required this.password});

  @override
  Widget build(BuildContext context) {
    final requirements = [
      _Requirement('At least 8 characters', password.length >= 8),
      _Requirement('Uppercase letter', RegExp(r'[A-Z]').hasMatch(password)),
      _Requirement('Lowercase letter', RegExp(r'[a-z]').hasMatch(password)),
      _Requirement('Number', RegExp(r'[0-9]').hasMatch(password)),
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: requirements.map((req) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              req.isMet ? Icons.check_circle : Icons.circle_outlined,
              size: 16,
              color: req.isMet ? AppColors.success : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              req.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: req.isMet ? AppColors.success : AppColors.textSecondary,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _Requirement {
  final String label;
  final bool isMet;

  const _Requirement(this.label, this.isMet);
}
