import '../../domain/entities/patient_profile_entity.dart';

class PatientProfileModel extends PatientProfileEntity {
  const PatientProfileModel({
    required super.id,
    required super.tenantId,
    required super.firstName,
    required super.lastName,
    required super.email,
    required super.phoneNumber,
    super.middleName,
    super.dateOfBirth,
    super.gender,
    super.addressLine1,
    super.addressLine2,
    super.city,
    super.country,
    super.postalCode,
    super.branchId,
    super.branchName,
    super.emergencyContact,
    super.insurances,
  });

  factory PatientProfileModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is String && v.isEmpty) return null;
      return DateTime.tryParse(v.toString());
    }

    // The API returns emergency contact as flat top-level fields, not a nested object.
    EmergencyContactEntity? emergencyContact;
    if (json['emergencyContact'] is Map<String, dynamic>) {
      emergencyContact = EmergencyContactModel.fromJson(
        json['emergencyContact'] as Map<String, dynamic>,
      );
    } else {
      final name = json['emergencyContactName']?.toString();
      final phone = json['emergencyContactPhone']?.toString();
      final relationship = json['emergencyContactRelationship']?.toString();
      final email = json['emergencyContactEmail']?.toString();
      if (name != null && name.isNotEmpty) {
        emergencyContact = EmergencyContactModel(
          name: name,
          relationship: relationship ?? '',
          phoneNumber: phone ?? '',
          email: (email != null && email.isNotEmpty) ? email : null,
        );
      }
    }

    final insurancesJson = json['insurances'];
    final insurances = (insurancesJson is List)
        ? insurancesJson
              .whereType<Map<String, dynamic>>()
              .map(InsurancePolicyModel.fromJson)
              .toList()
        : <InsurancePolicyModel>[];

    // Address: prefer separate fields; fall back to the combined address string.
    final rawAddress = json['address'] is String
        ? json['address'] as String
        : null;
    final addressLine1 =
        json['addressLine1']?.toString() ??
        (json['address'] is Map<String, dynamic>
            ? (json['address']['line1'] as String?)
            : null) ??
        rawAddress;
    final city =
        json['city']?.toString() ??
        (json['address'] is Map<String, dynamic>
            ? (json['address']['city'] as String?)
            : null);

    return PatientProfileModel(
      id: json['id']?.toString() ?? '',
      tenantId: json['tenantId']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      middleName: json['middleName']?.toString(),
      lastName: json['lastName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber:
          json['phoneNumber']?.toString() ?? json['phone']?.toString() ?? '',
      dateOfBirth: parseDate(json['dateOfBirth']),
      gender: json['gender']?.toString(),
      addressLine1: addressLine1,
      addressLine2: json['addressLine2']?.toString(),
      city: city,
      country: json['country']?.toString(),
      postalCode: json['postalCode']?.toString(),
      branchId:
          json['branchId']?.toString() ?? json['primaryBranchId']?.toString(),
      branchName: json['branchName']?.toString(),
      emergencyContact: emergencyContact,
      insurances: insurances,
    );
  }
}

class EmergencyContactModel extends EmergencyContactEntity {
  const EmergencyContactModel({
    required super.name,
    required super.relationship,
    required super.phoneNumber,
    super.email,
  });

  factory EmergencyContactModel.fromJson(Map<String, dynamic> json) {
    return EmergencyContactModel(
      name: json['name']?.toString() ?? json['contactName']?.toString() ?? '',
      relationship: json['relationship']?.toString() ?? '',
      phoneNumber:
          json['phoneNumber']?.toString() ??
          json['contactPhone']?.toString() ??
          '',
      email: json['email']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'relationship': relationship,
    'phoneNumber': phoneNumber,
    if (email != null) 'email': email,
  };
}

class InsurancePolicyModel extends InsurancePolicyEntity {
  const InsurancePolicyModel({
    required super.id,
    required super.providerName,
    required super.policyNumber,
    super.schemeName,
    super.memberNumber,
    super.validFrom,
    super.validTo,
    super.isPrimary,
  });

  factory InsurancePolicyModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    return InsurancePolicyModel(
      id: json['id']?.toString() ?? '',
      providerName:
          json['providerName']?.toString() ??
          json['insuranceProviderName']?.toString() ??
          'Insurance',
      schemeName:
          json['schemeName']?.toString() ??
          json['insuranceSchemeName']?.toString(),
      policyNumber: json['policyNumber']?.toString() ?? '',
      memberNumber: json['memberNumber']?.toString(),
      validFrom: parseDate(json['validFrom']),
      validTo: parseDate(json['validTo']),
      isPrimary: json['isPrimary'] as bool? ?? false,
    );
  }
}
