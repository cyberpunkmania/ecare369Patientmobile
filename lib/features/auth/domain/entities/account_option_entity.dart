import 'package:equatable/equatable.dart';

/// Account type for multi-tenant/multi-role authentication.
enum AccountType {
  platformAdmin,
  platformDoctor,
  platformPatient,
  tenantAdmin,
  tenantDoctor,
  tenantPatient;

  static AccountType fromString(String value) {
    switch (value) {
      case 'PlatformAdmin':
        return AccountType.platformAdmin;
      case 'PlatformDoctor':
        return AccountType.platformDoctor;
      case 'PlatformPatient':
        return AccountType.platformPatient;
      case 'TenantAdmin':
        return AccountType.tenantAdmin;
      case 'TenantDoctor':
        return AccountType.tenantDoctor;
      case 'TenantPatient':
        return AccountType.tenantPatient;
      default:
        return AccountType.tenantPatient;
    }
  }

  String toApiString() {
    switch (this) {
      case AccountType.platformAdmin:
        return 'PlatformAdmin';
      case AccountType.platformDoctor:
        return 'PlatformDoctor';
      case AccountType.platformPatient:
        return 'PlatformPatient';
      case AccountType.tenantAdmin:
        return 'TenantAdmin';
      case AccountType.tenantDoctor:
        return 'TenantDoctor';
      case AccountType.tenantPatient:
        return 'TenantPatient';
    }
  }

  String get displayName {
    switch (this) {
      case AccountType.platformAdmin:
        return 'Platform Admin';
      case AccountType.platformDoctor:
        return 'Platform Doctor';
      case AccountType.platformPatient:
        return 'Platform Patient';
      case AccountType.tenantAdmin:
        return 'Tenant Admin';
      case AccountType.tenantDoctor:
        return 'Tenant Doctor';
      case AccountType.tenantPatient:
        return 'Tenant Patient';
    }
  }
}

/// Account status determining which auth flow to use.
/// Maps to integer values from API: Active=0, Inactive=1, Onboarding=2
enum AccountStatus {
  active, // 0 - Flow A: Has password, can login with OTP → /generate-login-otp
  inactive, // 1 - Flow C: Was deactivated, needs reactivation → /fetch-security-questions
  onboarding; // 2 - Flow B: New account, needs first-time setup → /setup-account

  /// Parse from API integer or string value.
  static AccountStatus fromValue(dynamic value) {
    if (value is int) {
      return fromInt(value);
    }
    if (value is String) {
      // Try parsing as int first
      final intValue = int.tryParse(value);
      if (intValue != null) {
        return fromInt(intValue);
      }
      return fromString(value);
    }
    return AccountStatus.onboarding;
  }

  /// Parse from integer value (API sends 0, 1, 2).
  static AccountStatus fromInt(int value) {
    switch (value) {
      case 0:
        return AccountStatus.active;
      case 1:
        return AccountStatus.inactive;
      case 2:
        return AccountStatus.onboarding;
      default:
        return AccountStatus.onboarding;
    }
  }

  static AccountStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'active':
        return AccountStatus.active;
      case 'inactive':
        return AccountStatus.inactive;
      case 'onboarding':
        return AccountStatus.onboarding;
      default:
        return AccountStatus.onboarding;
    }
  }

  /// Convert to API integer value.
  int toApiInt() {
    switch (this) {
      case AccountStatus.active:
        return 0;
      case AccountStatus.inactive:
        return 1;
      case AccountStatus.onboarding:
        return 2;
    }
  }

  String toApiString() {
    switch (this) {
      case AccountStatus.active:
        return 'Active';
      case AccountStatus.inactive:
        return 'Inactive';
      case AccountStatus.onboarding:
        return 'Onboarding';
    }
  }
}

/// Represents a selectable account option from the lookup response.
class AccountOptionEntity extends Equatable {
  /// User ID - null ONLY for orphan patients (no User row yet).
  final String? userId;
  final AccountType accountType;
  final AccountStatus status;
  final String? tenantId;
  final String? tenantName;
  final String? tenantCode;
  final String? branchId;
  final String? branchName;
  final String? patientId;
  final String? patientNumber;
  final String? doctorId;
  final String? licenseNumber;
  final String? specialty;

  const AccountOptionEntity({
    this.userId,
    required this.accountType,
    required this.status,
    this.tenantId,
    this.tenantName,
    this.tenantCode,
    this.branchId,
    this.branchName,
    this.patientId,
    this.patientNumber,
    this.doctorId,
    this.licenseNumber,
    this.specialty,
  });

  /// Returns the display name for this account.
  String get displayName {
    if (tenantName != null && tenantName!.isNotEmpty) {
      return tenantName!;
    }
    return accountType.displayName;
  }

  /// Returns a subtitle for this account (e.g., patient number or specialty).
  String? get subtitle {
    if (patientNumber != null) return patientNumber;
    if (specialty != null) return specialty;
    if (licenseNumber != null) return licenseNumber;
    if (branchName != null) return branchName;
    return null;
  }

  /// Determines which auth flow to use based on status.
  AuthFlow get requiredFlow {
    switch (status) {
      case AccountStatus.active:
        return AuthFlow.activeLogin;
      case AccountStatus.inactive:
        return AuthFlow.reactivation;
      case AccountStatus.onboarding:
        return AuthFlow.onboarding;
    }
  }

  @override
  List<Object?> get props => [
    userId,
    accountType,
    status,
    tenantId,
    tenantName,
    tenantCode,
    branchId,
    branchName,
    patientId,
    patientNumber,
    doctorId,
    licenseNumber,
    specialty,
  ];
}

/// The three possible authentication flows.
enum AuthFlow {
  activeLogin, // Flow A: Password → OTP → JWT
  onboarding, // Flow B: Setup (password + security Qs) → OTP → JWT
  reactivation, // Flow C: Security Q&A → New password → JWT
}
