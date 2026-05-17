import '../../domain/entities/account_option_entity.dart';

/// Data model for AccountLoginOptionDto from the API.
class AccountOptionModel extends AccountOptionEntity {
  const AccountOptionModel({
    super.userId,
    required super.accountType,
    required super.status,
    super.tenantId,
    super.tenantName,
    super.tenantCode,
    super.branchId,
    super.branchName,
    super.patientId,
    super.patientNumber,
    super.doctorId,
    super.licenseNumber,
    super.specialty,
  });

  factory AccountOptionModel.fromJson(Map<String, dynamic> json) {
    return AccountOptionModel(
      userId: json['userId'] as String?,
      accountType: AccountType.fromString(
        json['accountType'] as String? ?? 'TenantPatient',
      ),
      // API sends status as integer (0=Active, 1=Inactive, 2=Onboarding)
      status: AccountStatus.fromValue(json['status'] ?? 2),
      tenantId: json['tenantId'] as String?,
      tenantName: json['tenantName'] as String?,
      tenantCode: json['tenantCode'] as String?,
      branchId: json['branchId'] as String?,
      branchName: json['branchName'] as String?,
      patientId: json['patientId'] as String?,
      patientNumber: json['patientNumber'] as String?,
      doctorId: json['doctorId'] as String?,
      licenseNumber: json['licenseNumber'] as String?,
      specialty: json['specialty'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'accountType': accountType.toApiString(),
      'status': status.toApiInt(),
      'tenantId': tenantId,
      'tenantName': tenantName,
      'tenantCode': tenantCode,
      'branchId': branchId,
      'branchName': branchName,
      'patientId': patientId,
      'patientNumber': patientNumber,
      'doctorId': doctorId,
      'licenseNumber': licenseNumber,
      'specialty': specialty,
    };
  }
}
