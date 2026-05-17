import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/patient_profile_entity.dart';

abstract class ProfileRepository {
  Future<Either<Failure, PatientProfileEntity>> getProfile(String patientId);

  Future<Either<Failure, PatientProfileEntity>> updateDemographics({
    required String patientId,
    DateTime? dateOfBirth,
    String? gender,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? country,
    String? postalCode,
  });

  Future<Either<Failure, PatientProfileEntity>> updateEmergencyContact({
    required String patientId,
    required EmergencyContactEntity contact,
  });

  Future<Either<Failure, PatientProfileEntity>> addInsurance({
    required String patientId,
    required String providerId,
    String? schemeId,
    required String policyNumber,
    String? memberNumber,
    DateTime? validFrom,
    DateTime? validTo,
    bool isPrimary = false,
  });

  Future<Either<Failure, PatientProfileEntity>> updateInsurance({
    required String patientId,
    required String insuranceId,
    required String providerName,
    required String policyNumber,
    String? memberNumber,
    DateTime? validFrom,
    DateTime? validTo,
    bool isPrimary = false,
  });

  Future<Either<Failure, PatientProfileEntity>> removeInsurance({
    required String patientId,
    required String insuranceId,
  });
}
