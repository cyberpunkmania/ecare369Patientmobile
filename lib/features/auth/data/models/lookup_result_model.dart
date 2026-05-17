import '../../domain/entities/lookup_result_entity.dart';
import 'account_option_model.dart';

/// Data model for LookupUserTenantsResponseDto from the API.
class LookupResultModel extends LookupResultEntity {
  const LookupResultModel({
    required super.userExists,
    required super.requiresAccountSelection,
    required super.requiresOnboarding,
    super.message,
    super.canLoginAccounts,
    super.inactiveAccounts,
    super.onboardingAccounts,
  });

  factory LookupResultModel.fromJson(Map<String, dynamic> json) {
    return LookupResultModel(
      userExists: json['userExists'] as bool? ?? false,
      requiresAccountSelection:
          json['requiresAccountSelection'] as bool? ?? false,
      requiresOnboarding: json['requiresOnboarding'] as bool? ?? false,
      message: json['message'] as String?,
      canLoginAccounts:
          (json['canLoginAccounts'] as List<dynamic>?)
              ?.map(
                (e) => AccountOptionModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      inactiveAccounts:
          (json['inactiveAccounts'] as List<dynamic>?)
              ?.map(
                (e) => AccountOptionModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      onboardingAccounts:
          (json['onboardingAccounts'] as List<dynamic>?)
              ?.map(
                (e) => AccountOptionModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userExists': userExists,
      'requiresAccountSelection': requiresAccountSelection,
      'requiresOnboarding': requiresOnboarding,
      'message': message,
      'canLoginAccounts': canLoginAccounts
          .map((e) => (e as AccountOptionModel).toJson())
          .toList(),
      'inactiveAccounts': inactiveAccounts
          .map((e) => (e as AccountOptionModel).toJson())
          .toList(),
      'onboardingAccounts': onboardingAccounts
          .map((e) => (e as AccountOptionModel).toJson())
          .toList(),
    };
  }
}
