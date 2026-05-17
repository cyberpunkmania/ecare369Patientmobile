import 'package:equatable/equatable.dart';

class PatientInsuranceDto extends Equatable {
  final String? id;
  final String? insurerName;
  final String? policyNumber;
  final String? memberNumber;
  final String? coverType;
  final bool isPrimary;

  const PatientInsuranceDto({
    this.id,
    this.insurerName,
    this.policyNumber,
    this.memberNumber,
    this.coverType,
    this.isPrimary = false,
  });

  factory PatientInsuranceDto.fromJson(Map<String, dynamic> json) {
    return PatientInsuranceDto(
      id: json['id'] as String?,
      insurerName: json['insurerName'] as String?,
      policyNumber: json['policyNumber'] as String?,
      memberNumber: json['memberNumber'] as String?,
      coverType: json['coverType'] as String?,
      isPrimary: json['isPrimary'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
    id,
    insurerName,
    policyNumber,
    memberNumber,
    coverType,
    isPrimary,
  ];
}

class PatientProfileDto extends Equatable {
  final String id;
  final String? outpatientNumber;
  final String? inpatientNumber;
  final String? tenantId;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String? fullName;
  final String? dateOfBirth;
  final int? age;
  final String? ageGroup;
  final String? gender;
  final String? maritalStatus;
  final String? nationalId;
  final String? passportNumber;
  final String? email;
  final String phoneNumber;
  final String? alternatePhone;
  final String? address;
  final String? city;
  final String? county;
  final String? country;
  final String? postalCode;
  final String? bloodGroup;
  final List<String> allergies;
  final List<String> chronicConditions;
  final List<String> currentMedications;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? emergencyContactRelationship;
  final String? emergencyContactEmail;
  final List<PatientInsuranceDto> insurances;
  final bool isActive;
  final String? patientType;
  final String? registrationSource;
  final bool hasUserAccount;
  final String? userId;
  final String? defaultBranchId;
  final String? registrationDate;
  final String? createdAt;
  final String? updatedAt;

  const PatientProfileDto({
    required this.id,
    this.outpatientNumber,
    this.inpatientNumber,
    this.tenantId,
    required this.firstName,
    this.middleName,
    required this.lastName,
    this.fullName,
    this.dateOfBirth,
    this.age,
    this.ageGroup,
    this.gender,
    this.maritalStatus,
    this.nationalId,
    this.passportNumber,
    this.email,
    required this.phoneNumber,
    this.alternatePhone,
    this.address,
    this.city,
    this.county,
    this.country,
    this.postalCode,
    this.bloodGroup,
    this.allergies = const [],
    this.chronicConditions = const [],
    this.currentMedications = const [],
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.emergencyContactRelationship,
    this.emergencyContactEmail,
    this.insurances = const [],
    this.isActive = true,
    this.patientType,
    this.registrationSource,
    this.hasUserAccount = false,
    this.userId,
    this.defaultBranchId,
    this.registrationDate,
    this.createdAt,
    this.updatedAt,
  });

  String get displayName =>
      fullName ??
      '$firstName${middleName != null ? ' $middleName' : ''} $lastName';

  factory PatientProfileDto.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    return PatientProfileDto(
      id: data['id'] as String? ?? '',
      outpatientNumber: data['outpatientNumber'] as String?,
      inpatientNumber: data['inpatientNumber'] as String?,
      tenantId: data['tenantId'] as String?,
      firstName: data['firstName'] as String? ?? '',
      middleName: data['middleName'] as String?,
      lastName: data['lastName'] as String? ?? '',
      fullName: data['fullName'] as String?,
      dateOfBirth: data['dateOfBirth'] as String?,
      age: data['age'] as int?,
      ageGroup: data['ageGroup'] as String?,
      gender: data['gender'] as String?,
      maritalStatus: data['maritalStatus'] as String?,
      nationalId: data['nationalId'] as String?,
      passportNumber: data['passportNumber'] as String?,
      email: data['email'] as String?,
      phoneNumber: data['phoneNumber'] as String? ?? '',
      alternatePhone: data['alternatePhone'] as String?,
      address: data['address'] as String?,
      city: data['city'] as String?,
      county: data['county'] as String?,
      country: data['country'] as String?,
      postalCode: data['postalCode'] as String?,
      bloodGroup: data['bloodGroup'] as String?,
      allergies: _toStringList(data['allergies']),
      chronicConditions: _toStringList(data['chronicConditions']),
      currentMedications: _toStringList(data['currentMedications']),
      emergencyContactName: data['emergencyContactName'] as String?,
      emergencyContactPhone: data['emergencyContactPhone'] as String?,
      emergencyContactRelationship:
          data['emergencyContactRelationship'] as String?,
      emergencyContactEmail: data['emergencyContactEmail'] as String?,
      insurances:
          (data['insurances'] as List<dynamic>?)
              ?.map(
                (e) => PatientInsuranceDto.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      isActive: data['isActive'] as bool? ?? true,
      patientType: data['patientType'] as String?,
      registrationSource: data['registrationSource'] as String?,
      hasUserAccount: data['hasUserAccount'] as bool? ?? false,
      userId: data['userId'] as String?,
      defaultBranchId: data['defaultBranchId'] as String?,
      registrationDate: data['registrationDate'] as String?,
      createdAt: data['createdAt'] as String?,
      updatedAt: data['updatedAt'] as String?,
    );
  }

  static List<String> _toStringList(dynamic value) {
    if (value is List) return value.map((e) => e.toString()).toList();
    return const [];
  }

  @override
  List<Object?> get props => [id, outpatientNumber, firstName, lastName];
}
