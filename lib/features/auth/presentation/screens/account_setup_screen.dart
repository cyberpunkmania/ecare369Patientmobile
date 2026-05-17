import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/theme_config.dart';
import '../../domain/entities/account_option_entity.dart';
import '../../domain/entities/security_question_entity.dart';
import '../../../../core/widgets/top_notification.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';

/// Account setup screen for onboarding flow (Flow B - Step 2).
/// Allows user to create password and answer security questions.
class AccountSetupScreen extends StatefulWidget {
  final String email;
  final AccountOptionEntity account;
  final List<String> securityQuestions;

  /// Password carried forward from self-registration.
  /// When provided, the password phase is skipped.
  final String? prefillPassword;

  const AccountSetupScreen({
    super.key,
    required this.email,
    required this.account,
    required this.securityQuestions,
    this.prefillPassword,
  });

  @override
  State<AccountSetupScreen> createState() => _AccountSetupScreenState();
}

class _AccountSetupScreenState extends State<AccountSetupScreen> {
  // Phase: 0 = password, 1..N = question at pool index (_step - 1)
  // Starts at 1 when a password is pre-filled from registration.
  late int _step;

  // ── Password phase ──
  final _passwordFormKey = GlobalKey<FormState>();
  final _passwordCtl = TextEditingController();
  final _confirmCtl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  // ── Question phase ──
  final Map<int, TextEditingController> _answerCtls = {};
  final Map<int, String> _answers = {};
  bool _fetchingMore = false;
  int _lastQuestionStep = 1; // step to return to from review

  TextEditingController _ctlFor(int index) {
    return _answerCtls.putIfAbsent(
      index,
      () => TextEditingController(text: _answers[index] ?? ''),
    );
  }

  int get _answeredCount =>
      _answers.values.where((a) => a.trim().isNotEmpty).length;

  bool get _canSubmit => _answeredCount >= 3;

  @override
  void initState() {
    super.initState();
    // Skip password phase when the registration password is pre-filled.
    _step = widget.prefillPassword != null ? 1 : 0;
  }

  @override
  void didUpdateWidget(covariant AccountSetupScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.securityQuestions.length != oldWidget.securityQuestions.length) {
      _fetchingMore = false;
    }
  }

  @override
  void dispose() {
    _passwordCtl.dispose();
    _confirmCtl.dispose();
    for (final c in _answerCtls.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Navigation ──

  void _goBack() {
    if (_step == 0) {
      context.read<AuthBloc>().add(const AuthBackRequested());
      return;
    }
    if (_step == -1) {
      // Return from review to last browsed question
      setState(() => _step = _lastQuestionStep);
      return;
    }
    _saveCurrentAnswer();
    setState(() => _step--);
  }

  void _goNext() {
    if (_step == 0) {
      if (!(_passwordFormKey.currentState?.validate() ?? false)) return;
      setState(() => _step = 1);
      return;
    }
    _saveCurrentAnswer();
    final pool = widget.securityQuestions;
    final qIdx = _step - 1;

    // Prefetch more when near the end of the pool
    if (qIdx >= pool.length - 2 && !_fetchingMore) {
      _fetchingMore = true;
      context.read<AuthBloc>().add(const FetchMoreSecurityQuestionsRequested());
    }

    // Auto-advance to review once 3 questions are answered
    if (_answeredCount >= 3) {
      _lastQuestionStep = _step;
      setState(() => _step = -1);
      return;
    }

    if (_step >= pool.length) return;
    setState(() => _step++);
  }

  void _saveCurrentAnswer() {
    if (_step <= 0) return;
    final idx = _step - 1;
    final text = _ctlFor(idx).text.trim();
    if (text.isNotEmpty) {
      _answers[idx] = text;
    } else {
      _answers.remove(idx);
    }
  }

  void _submit() {
    _saveCurrentAnswer();
    final pool = widget.securityQuestions;
    final inputs = _answers.entries
        .where((e) => e.value.trim().isNotEmpty && e.key < pool.length)
        .take(3)
        .map(
          (e) => SecurityQuestionAnswer.forOnboarding(
            question: pool[e.key],
            answer: e.value.trim(),
          ),
        )
        .toList();

    if (inputs.length < 3) {
      TopNotification.show(
        context,
        'Please answer at least 3 security questions',
        type: NotificationType.error,
      );
      return;
    }

    context.read<AuthBloc>().add(
      AccountSetupSubmitted(
        password: widget.prefillPassword ?? _passwordCtl.text,
        securityQuestions: inputs,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_step == 0) return _buildPasswordPhase();
    if (_step == -1) return _buildReviewPhase();
    return _buildQuestionPhase();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // REVIEW PHASE: Summary + Submit
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildReviewPhase() {
    final pool = widget.securityQuestions;
    final answeredEntries = _answers.entries
        .where((e) => e.value.trim().isNotEmpty && e.key < pool.length)
        .take(3)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _goBack,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Review & Submit',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please confirm your details before completing setup',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 28),

          // Password summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF3F3F46)
                  : AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_outline, color: AppColors.primary),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Password',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '•' * 10,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 20,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Security questions header
          Row(
            children: [
              Text(
                'Security Questions',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              _AnsweredBadge(count: answeredEntries.length),
            ],
          ),
          const SizedBox(height: 12),

          // Answered Q&A list
          ...answeredEntries.asMap().entries.map((entry) {
            final idx = entry.key;
            final qIdx = entry.value.key;
            final answer = entry.value.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF3F3F46)
                      : AppColors.success.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${idx + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            pool[qIdx],
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 34),
                      child: Text(
                        answer,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 8),

          // Edit questions link
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _goBack,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Change answers'),
            ),
          ),
          const SizedBox(height: 24),

          // Submit button
          SizedBox(
            height: 52,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _submit,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 22),
                  SizedBox(width: 8),
                  Text('Complete Setup', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PHASE 0: Password
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildPasswordPhase() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
      child: Form(
        key: _passwordFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _goBack,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Set Up Your Account',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a secure password to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),

            // Password
            TextFormField(
              controller: _passwordCtl,
              obscureText: _obscurePass,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePass
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (_) => setState(() {}),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a password';
                }
                if (value.length < 8) {
                  return 'Password must be at least 8 characters';
                }
                if (!RegExp(r'[A-Z]').hasMatch(value)) {
                  return 'Must contain an uppercase letter';
                }
                if (!RegExp(r'[a-z]').hasMatch(value)) {
                  return 'Must contain a lowercase letter';
                }
                if (!RegExp(r'[0-9]').hasMatch(value)) {
                  return 'Must contain a number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Confirm Password
            TextFormField(
              controller: _confirmCtl,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value != _passwordCtl.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _PasswordRequirements(password: _passwordCtl.text),
            const SizedBox(height: 32),

            // Next button
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: _goNext,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Next: Security Questions',
                      style: TextStyle(fontSize: 15),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PHASE 1+: Security Questions (one at a time)
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildQuestionPhase() {
    final pool = widget.securityQuestions;
    final qIdx = _step - 1;
    final questionText = pool[qIdx];
    final ctl = _ctlFor(qIdx);
    final isAnswered =
        (_answers[qIdx] ?? '').trim().isNotEmpty || ctl.text.trim().isNotEmpty;
    final isLast = _step >= pool.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Text(
            'Security Questions',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Pick any 3 questions to answer',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
              _AnsweredBadge(count: _answeredCount),
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar
          _QuestionProgressBar(
            total: pool.length,
            currentIndex: qIdx,
            answers: _answers,
          ),
          const SizedBox(height: 8),

          // Question X of Y
          Row(
            children: [
              Text(
                'Question ${qIdx + 1} of ${pool.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                'Tap arrows to browse',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Question card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF3F3F46)
                  : AppColors.primary.withOpacity(0.07),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              questionText,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Answer field
          TextFormField(
            controller: ctl,
            decoration: InputDecoration(
              labelText: 'Your answer',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: isAnswered
                  ? const Icon(Icons.check_circle, color: AppColors.success)
                  : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),

          // Navigation row
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _goBack,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_back, size: 18),
                      SizedBox(width: 8),
                      Text('Back'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (!isLast)
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _goNext,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Next'),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // Review button (visible when >= 3 answered)
          if (_canSubmit) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 50,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  _saveCurrentAnswer();
                  _lastQuestionStep = _step;
                  setState(() => _step = -1);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Review & Submit ($_answeredCount answered)',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Helper widgets
// ═══════════════════════════════════════════════════════════════════════════

class _PasswordRequirements extends StatelessWidget {
  final String password;

  const _PasswordRequirements({required this.password});

  @override
  Widget build(BuildContext context) {
    final reqs = [
      ('At least 8 characters', password.length >= 8),
      ('Uppercase letter', RegExp(r'[A-Z]').hasMatch(password)),
      ('Lowercase letter', RegExp(r'[a-z]').hasMatch(password)),
      ('Number', RegExp(r'[0-9]').hasMatch(password)),
    ];
    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: reqs.map((r) {
        final (label, met) = r;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              met ? Icons.check_circle : Icons.circle_outlined,
              size: 16,
              color: met ? AppColors.success : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: met ? AppColors.success : AppColors.textSecondary,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _QuestionProgressBar extends StatelessWidget {
  final int total;
  final int currentIndex;
  final Map<int, String> answers;

  const _QuestionProgressBar({
    required this.total,
    required this.currentIndex,
    required this.answers,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 6,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segW = constraints.maxWidth / total;
          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.12)
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              ...List.generate(total, (i) {
                final answered = (answers[i] ?? '').trim().isNotEmpty;
                if (!answered) return const SizedBox.shrink();
                return Positioned(
                  left: i * segW,
                  width: segW - 1,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                );
              }),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                left: currentIndex * segW,
                width: segW - 1,
                top: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AnsweredBadge extends StatelessWidget {
  final int count;

  const _AnsweredBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: count >= 3 ? AppColors.success : AppColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count/3',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
