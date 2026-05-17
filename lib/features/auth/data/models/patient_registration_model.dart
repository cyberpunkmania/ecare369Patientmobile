import '../../domain/entities/patient_registration_entity.dart';

/// Request model for patient registration.
class PatientRegistrationRequestModel extends PatientRegistrationRequest {
  const PatientRegistrationRequestModel({
    required super.tenantId,
    required super.firstName,
    required super.lastName,
    required super.phoneNumber,
    required super.email,
    required super.patientType,
    required super.dateOfBirth,
    required super.gender,
    super.password,
    super.middleName,
    super.street,
    super.building,
    super.city,
    super.county,
    super.country,
    super.postalCode,
    super.landMark,
  });

  factory PatientRegistrationRequestModel.fromEntity(
    PatientRegistrationRequest entity,
  ) {
    return PatientRegistrationRequestModel(
      tenantId: entity.tenantId,
      firstName: entity.firstName,
      lastName: entity.lastName,
      phoneNumber: entity.phoneNumber,
      email: entity.email,
      patientType: entity.patientType,
      dateOfBirth: entity.dateOfBirth,
      gender: entity.gender,
      password: entity.password,
      middleName: entity.middleName,
      street: entity.street,
      building: entity.building,
      city: entity.city,
      county: entity.county,
      country: entity.country,
      postalCode: entity.postalCode,
      landMark: entity.landMark,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenantId': tenantId,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'email': email,
      'patientType': patientType.toApiString(),
      'dateOfBirth': dateOfBirth.toIso8601String().split('T').first,
      'gender': gender.toApiString(),
      if (password != null) 'password': password,
      if (middleName != null) 'middleName': middleName,
      if (street != null) 'street': street,
      if (building != null) 'building': building,
      if (city != null) 'city': city,
      if (county != null) 'county': county,
      if (country != null) 'country': country,
      if (postalCode != null) 'postalCode': postalCode,
      if (landMark != null) 'landMark': landMark,
    };
  }
}

/// Model for patient insurance DTO.
class PatientInsuranceModel extends PatientInsuranceEntity {
  const PatientInsuranceModel({
    required super.id,
    required super.insuranceSchemeId,
    required super.insuranceProvider,
    required super.policyNumber,
    super.memberNumber,
    super.policyStartDate,
    super.policyEndDate,
    required super.isPrimary,
    required super.isActive,
    required super.isExpired,
    required super.addedDate,
    super.deactivatedDate,
  });

  factory PatientInsuranceModel.fromJson(Map<String, dynamic> json) {
    return PatientInsuranceModel(
      id: json['id'] as String? ?? '',
      insuranceSchemeId: json['insuranceSchemeId'] as String? ?? '',
      insuranceProvider: json['insuranceProvider'] as String? ?? '',
      policyNumber: json['policyNumber'] as String? ?? '',
      memberNumber: json['memberNumber'] as String?,
      policyStartDate: _parseDateTime(json['policyStartDate']),
      policyEndDate: _parseDateTime(json['policyEndDate']),
      isPrimary: json['isPrimary'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      isExpired: json['isExpired'] as bool? ?? false,
      addedDate: _parseDateTime(json['addedDate']) ?? DateTime.now(),
      deactivatedDate: _parseDateTime(json['deactivatedDate']),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'insuranceSchemeId': insuranceSchemeId,
      'insuranceProvider': insuranceProvider,
      'policyNumber': policyNumber,
      'memberNumber': memberNumber,
      'policyStartDate': policyStartDate?.toIso8601String(),
      'policyEndDate': policyEndDate?.toIso8601String(),
      'isPrimary': isPrimary,
      'isActive': isActive,
      'isExpired': isExpired,
      'addedDate': addedDate.toIso8601String(),
      'deactivatedDate': deactivatedDate?.toIso8601String(),
    };
  }
}

/// Response model for patient registration (PatientDto).
class PatientModel extends PatientEntity {
  const PatientModel({
    required super.id,
    required super.tenantId,
    required super.patientNumber,
    required super.firstName,
    super.middleName,
    required super.lastName,
    required super.fullName,
    required super.email,
    super.phoneNumber,
    super.dateOfBirth,
    super.gender,
    required super.age,
    required super.ageGroup,
    super.bloodGroup,
    super.address,
    super.emergencyContactName,
    super.emergencyContactPhone,
    super.emergencyContactRelationship,
    super.emergencyContactEmail,
    super.allergies,
    super.chronicConditions,
    super.currentMedications,
    required super.hasUserAccount,
    super.userId,
    required super.patientType,
    required super.registrationSource,
    required super.registrationDate,
    super.defaultBranchId,
    required super.isActive,
    super.insurances,
    required super.createdAt,
    super.updatedAt,
    super.createdBy,
    super.updatedBy,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    // Handle nested data wrapper if present
    final data = json['data'] as Map<String, dynamic>? ?? json;

    return PatientModel(
      id: data['id'] as String? ?? '',
      tenantId: data['tenantId'] as String? ?? '',
      patientNumber: data['patientNumber'] as String? ?? '',
      firstName: data['firstName'] as String? ?? '',
      middleName: data['middleName'] as String?,
      lastName: data['lastName'] as String? ?? '',
      fullName: data['fullName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phoneNumber: data['phoneNumber'] as String?,
      dateOfBirth: _parseDateTime(data['dateOfBirth']),
      gender: data['gender'] as String?,
      age: data['age'] as int? ?? 0,
      ageGroup: data['ageGroup'] as String? ?? '',
      bloodGroup: data['bloodGroup'] as String?,
      address: data['address'] as String?,
      emergencyContactName: data['emergencyContactName'] as String?,
      emergencyContactPhone: data['emergencyContactPhone'] as String?,
      emergencyContactRelationship:
          data['emergencyContactRelationship'] as String?,
      emergencyContactEmail: data['emergencyContactEmail'] as String?,
      allergies: _parseStringList(data['allergies']),
      chronicConditions: _parseStringList(data['chronicConditions']),
      currentMedications: _parseStringList(data['currentMedications']),
      hasUserAccount: data['hasUserAccount'] as bool? ?? false,
      userId: data['userId'] as String?,
      patientType: data['patientType'] as String? ?? '',
      registrationSource: data['registrationSource'] as String? ?? '',
      registrationDate:
          _parseDateTime(data['registrationDate']) ?? DateTime.now(),
      defaultBranchId: data['defaultBranchId'] as String?,
      isActive: data['isActive'] as bool? ?? true,
      insurances: _parseInsurances(data['insurances']),
      createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(data['updatedAt']),
      createdBy: data['createdBy'] as String?,
      updatedBy: data['updatedBy'] as String?,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  static List<PatientInsuranceModel> _parseInsurances(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .map((e) => PatientInsuranceModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenantId': tenantId,
      'patientNumber': patientNumber,
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'age': age,
      'ageGroup': ageGroup,
      'bloodGroup': bloodGroup,
      'address': address,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'emergencyContactRelationship': emergencyContactRelationship,
      'emergencyContactEmail': emergencyContactEmail,
      'allergies': allergies,
      'chronicConditions': chronicConditions,
      'currentMedications': currentMedications,
      'hasUserAccount': hasUserAccount,
      'userId': userId,
      'patientType': patientType,
      'registrationSource': registrationSource,
      'registrationDate': registrationDate.toIso8601String(),
      'defaultBranchId': defaultBranchId,
      'isActive': isActive,
      'insurances': insurances
          .map((i) => (i as PatientInsuranceModel).toJson())
          .toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
    };
  }
}
