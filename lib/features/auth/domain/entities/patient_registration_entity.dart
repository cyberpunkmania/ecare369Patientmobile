import 'package:equatable/equatable.dart';

/// Gender options for patient registration.
enum Gender {
  male,
  female,
  other,
  preferNotToSay;

  static Gender fromString(String value) {
    switch (value.toLowerCase()) {
      case 'male':
        return Gender.male;
      case 'female':
        return Gender.female;
      case 'other':
        return Gender.other;
      case 'prefernotosay':
        return Gender.preferNotToSay;
      default:
        return Gender.preferNotToSay;
    }
  }

  String toApiString() {
    switch (this) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
      case Gender.other:
        return 'Other';
      case Gender.preferNotToSay:
        return 'PreferNotToSay';
    }
  }
}

/// Patient type for registration.
enum PatientType {
  /// Walk-in, no user account.
  visitor,

  /// Self-registered with password/user account.
  patientUser;

  static PatientType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'visitor':
        return PatientType.visitor;
      case 'patientuser':
        return PatientType.patientUser;
      default:
        return PatientType.visitor;
    }
  }

  String toApiString() {
    switch (this) {
      case PatientType.visitor:
        return 'Visitor';
      case PatientType.patientUser:
        return 'PatientUser';
    }
  }
}

/// Registration source (returned in PatientDto).
enum RegistrationSource {
  selfRegistration,
  visitorRegistration,
  guestRegistration,
  adminRegistration,
  importedData;

  static RegistrationSource fromString(String value) {
    switch (value) {
      case 'SelfRegistration':
        return RegistrationSource.selfRegistration;
      case 'VisitorRegistration':
        return RegistrationSource.visitorRegistration;
      case 'GuestRegistration':
        return RegistrationSource.guestRegistration;
      case 'AdminRegistration':
        return RegistrationSource.adminRegistration;
      case 'ImportedData':
        return RegistrationSource.importedData;
      default:
        return RegistrationSource.selfRegistration;
    }
  }

  String toApiString() {
    switch (this) {
      case RegistrationSource.selfRegistration:
        return 'SelfRegistration';
      case RegistrationSource.visitorRegistration:
        return 'VisitorRegistration';
      case RegistrationSource.guestRegistration:
        return 'GuestRegistration';
      case RegistrationSource.adminRegistration:
        return 'AdminRegistration';
      case RegistrationSource.importedData:
        return 'ImportedData';
    }
  }
}

/// Request entity for patient registration.
class PatientRegistrationRequest extends Equatable {
  /// Required - Tenant/organization ID.
  final String tenantId;

  /// Required - First name (max 100 chars).
  final String firstName;

  /// Required - Last name (max 100 chars).
  final String lastName;

  /// Required - Phone number (regex: ^\+?\d{9,15}$).
  final String phoneNumber;

  /// Required - Valid email format.
  final String email;

  /// Required - Patient type.
  final PatientType patientType;

  /// Required - Date of birth (must not be in future).
  final DateTime dateOfBirth;

  /// Required - Gender.
  final Gender gender;

  /// Required when patientType = PatientUser.
  final String? password;

  // Optional fields
  final String? middleName;
  final String? street;
  final String? building;
  final String? city;
  final String? county;
  final String? country;
  final String? postalCode;
  final String? landMark;

  const PatientRegistrationRequest({
    required this.tenantId,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.email,
    required this.patientType,
    required this.dateOfBirth,
    required this.gender,
    this.password,
    this.middleName,
    this.street,
    this.building,
    this.city,
    this.county,
    this.country,
    this.postalCode,
    this.landMark,
  });

  @override
  List<Object?> get props => [
    tenantId,
    firstName,
    lastName,
    phoneNumber,
    email,
    patientType,
    dateOfBirth,
    gender,
    password,
    middleName,
    street,
    building,
    city,
    county,
    country,
    postalCode,
    landMark,
  ];
}

/// Patient insurance DTO.
class PatientInsuranceEntity extends Equatable {
  final String id;
  final String insuranceSchemeId;
  final String insuranceProvider;
  final String policyNumber;
  final String? memberNumber;
  final DateTime? policyStartDate;
  final DateTime? policyEndDate;
  final bool isPrimary;
  final bool isActive;
  final bool isExpired;
  final DateTime addedDate;
  final DateTime? deactivatedDate;

  const PatientInsuranceEntity({
    required this.id,
    required this.insuranceSchemeId,
    required this.insuranceProvider,
    required this.policyNumber,
    this.memberNumber,
    this.policyStartDate,
    this.policyEndDate,
    required this.isPrimary,
    required this.isActive,
    required this.isExpired,
    required this.addedDate,
    this.deactivatedDate,
  });

  @override
  List<Object?> get props => [
    id,
    insuranceSchemeId,
    insuranceProvider,
    policyNumber,
    memberNumber,
    policyStartDate,
    policyEndDate,
    isPrimary,
    isActive,
    isExpired,
    addedDate,
    deactivatedDate,
  ];
}

/// Response entity from patient registration (PatientDto).
class PatientEntity extends Equatable {
  final String id;
  final String tenantId;
  final String patientNumber;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final DateTime? dateOfBirth;
  final String? gender;
  final int age;
  final String ageGroup;
  final String? bloodGroup;
  final String? address;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? emergencyContactRelationship;
  final String? emergencyContactEmail;
  final List<String> allergies;
  final List<String> chronicConditions;
  final List<String> currentMedications;
  final bool hasUserAccount;
  final String? userId;
  final String patientType;
  final String registrationSource;
  final DateTime registrationDate;
  final String? defaultBranchId;
  final bool isActive;
  final List<PatientInsuranceEntity> insurances;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? updatedBy;

  const PatientEntity({
    required this.id,
    required this.tenantId,
    required this.patientNumber,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.dateOfBirth,
    this.gender,
    required this.age,
    required this.ageGroup,
    this.bloodGroup,
    this.address,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.emergencyContactRelationship,
    this.emergencyContactEmail,
    this.allergies = const [],
    this.chronicConditions = const [],
    this.currentMedications = const [],
    required this.hasUserAccount,
    this.userId,
    required this.patientType,
    required this.registrationSource,
    required this.registrationDate,
    this.defaultBranchId,
    required this.isActive,
    this.insurances = const [],
    required this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
  });

  @override
  List<Object?> get props => [
    id,
    tenantId,
    patientNumber,
    firstName,
    middleName,
    lastName,
    fullName,
    email,
    phoneNumber,
    dateOfBirth,
    gender,
    age,
    ageGroup,
    bloodGroup,
    address,
    emergencyContactName,
    emergencyContactPhone,
    emergencyContactRelationship,
    emergencyContactEmail,
    allergies,
    chronicConditions,
    currentMedications,
    hasUserAccount,
    userId,
    patientType,
    registrationSource,
    registrationDate,
    defaultBranchId,
    isActive,
    insurances,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
  ];
}
