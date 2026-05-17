import '../../domain/entities/otp_response_entity.dart';

/// Data model for GenerateLoginOtpResponseDto and SetupAccountResponseDto.
class OtpResponseModel extends OtpResponseEntity {
  const OtpResponseModel({
    required super.userId,
    super.tenantId,
    required super.maskedEmail,
    required super.otpExpiresAt,
  });

  factory OtpResponseModel.fromJson(Map<String, dynamic> json) {
    return OtpResponseModel(
      userId: json['userId'] as String? ?? '',
      tenantId: json['tenantId'] as String?,
      maskedEmail: json['maskedEmail'] as String? ?? '',
      otpExpiresAt: _parseDateTime(json['otpExpiresAt']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) {
      // Default to 5 minutes from now if not provided
      return DateTime.now().add(const Duration(minutes: 5));
    }
    if (value is String) {
      return DateTime.parse(value);
    }
    return DateTime.now().add(const Duration(minutes: 5));
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'tenantId': tenantId,
      'maskedEmail': maskedEmail,
      'otpExpiresAt': otpExpiresAt.toIso8601String(),
    };
  }
}
