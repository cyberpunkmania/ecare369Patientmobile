import 'package:equatable/equatable.dart';

import 'account_option_entity.dart';

/// Result of the email lookup API call.
/// Determines which auth flow(s) the user can proceed with.
class LookupResultEntity extends Equatable {
  /// Whether any user account exists for this email.
  final bool userExists;

  /// True if total accounts > 1, requiring user to pick one.
  final bool requiresAccountSelection;

  /// True if any onboarding accounts exist.
  final bool requiresOnboarding;

  /// Message from the server (e.g., "Multiple accounts found").
  final String? message;

  /// Accounts with status = Active → Flow A.
  final List<AccountOptionEntity> canLoginAccounts;

  /// Accounts with status = Inactive → Flow C.
  final List<AccountOptionEntity> inactiveAccounts;

  /// Accounts with status = Onboarding → Flow B.
  final List<AccountOptionEntity> onboardingAccounts;

  const LookupResultEntity({
    required this.userExists,
    required this.requiresAccountSelection,
    required this.requiresOnboarding,
    this.message,
    this.canLoginAccounts = const [],
    this.inactiveAccounts = const [],
    this.onboardingAccounts = const [],
  });

  /// Returns all accounts combined for display in account picker.
  List<AccountOptionEntity> get allAccounts => [
    ...canLoginAccounts,
    ...onboardingAccounts,
    ...inactiveAccounts,
  ];

  /// Total number of accounts found.
  int get totalAccounts => allAccounts.length;

  /// Whether the user should see the account picker.
  bool get shouldShowAccountPicker => totalAccounts > 1;

  /// If only one account exists, return it directly.
  AccountOptionEntity? get singleAccount =>
      totalAccounts == 1 ? allAccounts.first : null;

  @override
  List<Object?> get props => [
    userExists,
    requiresAccountSelection,
    requiresOnboarding,
    message,
    canLoginAccounts,
    inactiveAccounts,
    onboardingAccounts,
  ];
}
