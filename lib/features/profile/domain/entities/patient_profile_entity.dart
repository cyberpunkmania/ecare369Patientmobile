import 'package:equatable/equatable.dart';

/// Pure domain entity for a patient profile fetched from
/// `GET /api/patients/{id}`.
class PatientProfileEntity extends Equatable {
  final String id;
  final String tenantId;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? country;
  final String? postalCode;
  final String? branchId;
  final String? branchName;

  final EmergencyContactEntity? emergencyContact;
  final List<InsurancePolicyEntity> insurances;

  const PatientProfileEntity({
    required this.id,
    required this.tenantId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    this.middleName,
    this.dateOfBirth,
    this.gender,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.country,
    this.postalCode,
    this.branchId,
    this.branchName,
    this.emergencyContact,
    this.insurances = const [],
  });

  String get fullName {
    if (middleName != null && middleName!.isNotEmpty) {
      return '$firstName ${middleName![0]}. $lastName';
    }
    return '$firstName $lastName';
  }

  int? get age {
    final dob = dateOfBirth;
    if (dob == null) return null;
    final now = DateTime.now();
    var years = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      years--;
    }
    return years;
  }

  PatientProfileEntity copyWith({
    DateTime? dateOfBirth,
    String? gender,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? country,
    String? postalCode,
    EmergencyContactEntity? emergencyContact,
    List<InsurancePolicyEntity>? insurances,
  }) {
    return PatientProfileEntity(
      id: id,
      tenantId: tenantId,
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      email: email,
      phoneNumber: phoneNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
      branchId: branchId,
      branchName: branchName,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      insurances: insurances ?? this.insurances,
    );
  }

  @override
  List<Object?> get props => [
    id,
    tenantId,
    firstName,
    lastName,
    email,
    phoneNumber,
    dateOfBirth,
    gender,
    addressLine1,
    city,
    country,
    branchId,
    emergencyContact,
    insurances,
  ];
}

class EmergencyContactEntity extends Equatable {
  final String name;
  final String relationship;
  final String phoneNumber;
  final String? email;

  const EmergencyContactEntity({
    required this.name,
    required this.relationship,
    required this.phoneNumber,
    this.email,
  });

  @override
  List<Object?> get props => [name, relationship, phoneNumber, email];
}

class InsurancePolicyEntity extends Equatable {
  final String id;
  final String providerName;
  final String? schemeName;
  final String policyNumber;
  final String? memberNumber;
  final DateTime? validFrom;
  final DateTime? validTo;
  final bool isPrimary;

  const InsurancePolicyEntity({
    required this.id,
    required this.providerName,
    required this.policyNumber,
    this.schemeName,
    this.memberNumber,
    this.validFrom,
    this.validTo,
    this.isPrimary = false,
  });

  bool get isActive {
    final now = DateTime.now();
    if (validFrom != null && now.isBefore(validFrom!)) return false;
    if (validTo != null && now.isAfter(validTo!)) return false;
    return true;
  }

  @override
  List<Object?> get props => [
    id,
    providerName,
    schemeName,
    policyNumber,
    memberNumber,
    validFrom,
    validTo,
    isPrimary,
  ];
}
