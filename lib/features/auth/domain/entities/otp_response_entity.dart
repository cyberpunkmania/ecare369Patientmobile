import 'package:equatable/equatable.dart';

/// Response after generating/sending an OTP code.
/// Used in Flow A (generate-login-otp) and Flow B (setup-account).
class OtpResponseEntity extends Equatable {
  final String userId;
  final String? tenantId;

  /// Masked email for display (e.g., "l***d@gmail.com").
  final String maskedEmail;

  /// ISO DateTime when the OTP expires — show countdown timer.
  final DateTime otpExpiresAt;

  const OtpResponseEntity({
    required this.userId,
    this.tenantId,
    required this.maskedEmail,
    required this.otpExpiresAt,
  });

  /// Returns the remaining time until OTP expiry.
  Duration get remainingTime {
    final now = DateTime.now();
    if (otpExpiresAt.isBefore(now)) {
      return Duration.zero;
    }
    return otpExpiresAt.difference(now);
  }

  /// Whether the OTP has expired.
  bool get isExpired => remainingTime == Duration.zero;

  @override
  List<Object?> get props => [userId, tenantId, maskedEmail, otpExpiresAt];
}
