import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/patient_profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';
import '../models/patient_profile_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  ProfileRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  Future<Either<Failure, PatientProfileEntity>> _guard(
    Future<PatientProfileModel> Function() action,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final value = await action();
      return Right(value);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, PatientProfileEntity>> getProfile(String patientId) =>
      _guard(() => remoteDataSource.getProfile(patientId));

  @override
  Future<Either<Failure, PatientProfileEntity>> updateDemographics({
    required String patientId,
    DateTime? dateOfBirth,
    String? gender,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? country,
    String? postalCode,
  }) {
    final body = <String, dynamic>{
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth.toIso8601String(),
      if (gender != null) 'gender': gender,
      if (addressLine1 != null) 'street': addressLine1,
      if (addressLine2 != null) 'building': addressLine2,
      if (city != null) 'city': city,
      if (country != null) 'country': country,
      if (postalCode != null) 'postalCode': postalCode,
    };
    return _guard(
      () =>
          remoteDataSource.updateDemographics(patientId: patientId, body: body),
    );
  }

  @override
  Future<Either<Failure, PatientProfileEntity>> updateEmergencyContact({
    required String patientId,
    required EmergencyContactEntity contact,
  }) {
    final body = <String, dynamic>{
      'contactName': contact.name,
      'relationship': contact.relationship,
      'contactPhone': contact.phoneNumber,
      if (contact.email != null) 'contactEmail': contact.email,
    };
    return _guard(
      () => remoteDataSource.updateEmergencyContact(
        patientId: patientId,
        body: body,
      ),
    );
  }

  @override
  Future<Either<Failure, PatientProfileEntity>> addInsurance({
    required String patientId,
    required String providerId,
    String? schemeId,
    required String policyNumber,
    String? memberNumber,
    DateTime? validFrom,
    DateTime? validTo,
    bool isPrimary = false,
  }) {
    final body = <String, dynamic>{
      if (schemeId != null) 'insuranceSchemeId': schemeId,
      'insuranceCompany': providerId,
      'policyNumber': policyNumber,
      if (memberNumber != null) 'memberNumber': memberNumber,
      if (validFrom != null) 'policyStartDate': validFrom.toIso8601String(),
      if (validTo != null) 'policyEndDate': validTo.toIso8601String(),
      'isPrimary': isPrimary,
    };
    return _guard(
      () => remoteDataSource.addInsurance(patientId: patientId, body: body),
    );
  }

  @override
  Future<Either<Failure, PatientProfileEntity>> removeInsurance({
    required String patientId,
    required String insuranceId,
  }) => _guard(
    () => remoteDataSource.removeInsurance(
      patientId: patientId,
      insuranceId: insuranceId,
    ),
  );

  @override
  Future<Either<Failure, PatientProfileEntity>> updateInsurance({
    required String patientId,
    required String insuranceId,
    required String providerName,
    required String policyNumber,
    String? memberNumber,
    DateTime? validFrom,
    DateTime? validTo,
    bool isPrimary = false,
  }) {
    final body = <String, dynamic>{
      'insuranceCompany': providerName,
      'policyNumber': policyNumber,
      if (memberNumber != null) 'memberNumber': memberNumber,
      if (validFrom != null) 'policyStartDate': validFrom.toIso8601String(),
      if (validTo != null) 'policyEndDate': validTo.toIso8601String(),
      'isPrimary': isPrimary,
    };
    return _guard(
      () => remoteDataSource.updateInsurance(
        patientId: patientId,
        insuranceId: insuranceId,
        body: body,
      ),
    );
  }
}
