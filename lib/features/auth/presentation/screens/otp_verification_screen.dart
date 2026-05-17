import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/theme_config.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';

/// OTP verification screen for both Flow A Step 3 and Flow B Step 3.
class OtpVerificationScreen extends StatefulWidget {
  final String maskedEmail;
  final DateTime? otpExpiresAt;
  final String flowContext; // 'login' or 'onboarding'

  const OtpVerificationScreen({
    super.key,
    required this.maskedEmail,
    this.otpExpiresAt,
    this.flowContext = 'login',
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _resendEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  bool get _isComplete => _otpCode.length == 6;

  bool _isSubmitting = false;

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }

    setState(() {});

    if (_isComplete) {
      _onSubmit();
    }
  }

  void _onKeyPressed(int index, RawKeyEvent event) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  void _onSubmit() {
    if (!_isComplete || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    context.read<AuthBloc>().add(OtpSubmitted(otp: _otpCode));

    // Re-enable after a short delay so user can retry on error
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isSubmitting = false);
    });
  }

  void _onResend() {
    if (!_resendEnabled) return;

    context.read<AuthBloc>().add(const ResendOtpRequested());

    setState(() => _resendEnabled = false);

    // Re-enable after 30 seconds
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        setState(() => _resendEnabled = true);
      }
    });

    // Clear fields
    for (final controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
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

          // ── Icon ──
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.email_outlined,
              size: 36,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),

          // ── Header ──
          Text(
            'Verify OTP',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the 6-digit code sent to\n${widget.maskedEmail}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // ── OTP Input Fields ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(6, (index) {
              return SizedBox(
                width: 44,
                child: RawKeyboardListener(
                  focusNode: FocusNode(),
                  onKey: (event) => _onKeyPressed(index, event),
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) => _onDigitChanged(index, value),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),

          // ── Expiry Info ──
          if (widget.otpExpiresAt != null)
            _ExpiryCountdown(expiresAt: widget.otpExpiresAt!),

          const SizedBox(height: 32),

          // ── Verify Button ──
          FilledButton(
            onPressed: _isComplete ? _onSubmit : null,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text('Verify'),
            ),
          ),
          const SizedBox(height: 16),

          // ── Resend Link ──
          Center(
            child: TextButton(
              onPressed: _resendEnabled ? _onResend : null,
              child: Text(
                _resendEnabled
                    ? "Didn't receive the code? Resend"
                    : 'Please wait before resending',
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Widget to show countdown for OTP expiry.
class _ExpiryCountdown extends StatefulWidget {
  final DateTime expiresAt;

  const _ExpiryCountdown({required this.expiresAt});

  @override
  State<_ExpiryCountdown> createState() => _ExpiryCountdownState();
}

class _ExpiryCountdownState extends State<_ExpiryCountdown> {
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _startTimer();
  }

  void _updateRemaining() {
    _remaining = widget.expiresAt.difference(DateTime.now());
    if (_remaining.isNegative) {
      _remaining = Duration.zero;
    }
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(_updateRemaining);
      return _remaining > Duration.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining <= Duration.zero) {
      return Text(
        'OTP has expired. Please request a new one.',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppColors.error),
        textAlign: TextAlign.center,
      );
    }

    final minutes = _remaining.inMinutes;
    final seconds = _remaining.inSeconds % 60;

    return Text(
      'Code expires in ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
      textAlign: TextAlign.center,
    );
  }
}
