import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/patient_registration_entity.dart';
import '../repositories/auth_repository.dart';

/// Use case for patient self-registration.
///
/// Registers a new patient with PatientType = PatientUser.
/// Creates both Patient and User records with status = PendingVerification.
/// After registration, the user should proceed to login → lookup → setup → confirm.
class RegisterPatientUseCase {
  final AuthRepository _repository;

  RegisterPatientUseCase({required AuthRepository repository})
    : _repository = repository;

  /// Registers a new patient.
  ///
  /// [request] contains all registration fields including:
  /// - Required: tenantId, firstName, lastName, phoneNumber, email,
  ///   dateOfBirth, gender, password (for PatientUser type)
  /// - Optional: middleName, street, building, city, etc.
  ///
  /// Returns [PatientEntity] with the created patient information.
  ///
  /// Errors:
  /// - 409: "A patient with this email is already registered in this tenant"
  /// - 400: "Password required for PatientUser registration"
  /// - 400: Validation errors
  Future<Either<Failure, PatientEntity>> call({
    required PatientRegistrationRequest request,
  }) {
    return _repository.registerPatient(request: request);
  }
}
