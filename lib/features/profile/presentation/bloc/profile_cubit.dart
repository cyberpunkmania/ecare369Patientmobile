import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/secure_storage.dart';
import '../../domain/entities/patient_profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileState extends Equatable {
  final bool loading;
  final bool saving;
  final PatientProfileEntity? profile;
  final String? errorMessage;
  final String? successMessage;

  const ProfileState({
    this.loading = false,
    this.saving = false,
    this.profile,
    this.errorMessage,
    this.successMessage,
  });

  const ProfileState.initial() : this();

  ProfileState copyWith({
    bool? loading,
    bool? saving,
    PatientProfileEntity? profile,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return ProfileState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      profile: profile ?? this.profile,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
    loading,
    saving,
    profile,
    errorMessage,
    successMessage,
  ];
}

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository repository;
  final SecureStorage secureStorage;

  ProfileCubit({required this.repository, required this.secureStorage})
    : super(const ProfileState.initial());

  Future<String?> _patientId() async {
    final pid = await secureStorage.getPatientId();
    if (pid == null || pid.isEmpty) return null;
    return pid;
  }

  Future<void> load() async {
    final id = await _patientId();
    if (id == null) {
      emit(
        state.copyWith(
          errorMessage: 'You are not signed in as a patient yet.',
          loading: false,
        ),
      );
      return;
    }
    emit(state.copyWith(loading: true, clearError: true, clearSuccess: true));
    final res = await repository.getProfile(id);
    res.fold(
      (f) => emit(state.copyWith(loading: false, errorMessage: f.message)),
      (p) => emit(state.copyWith(loading: false, profile: p)),
    );
  }

  Future<void> updateDemographics({
    DateTime? dateOfBirth,
    String? gender,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? country,
    String? postalCode,
  }) async {
    final id = state.profile?.id ?? await _patientId();
    if (id == null) return;
    emit(state.copyWith(saving: true, clearError: true, clearSuccess: true));
    final res = await repository.updateDemographics(
      patientId: id,
      dateOfBirth: dateOfBirth,
      gender: gender,
      addressLine1: addressLine1,
      addressLine2: addressLine2,
      city: city,
      country: country,
      postalCode: postalCode,
    );
    res.fold(
      (f) => emit(state.copyWith(saving: false, errorMessage: f.message)),
      (p) => emit(
        state.copyWith(
          saving: false,
          profile: p,
          successMessage: 'Demographics saved.',
        ),
      ),
    );
  }

  Future<void> updateEmergencyContact(EmergencyContactEntity contact) async {
    final id = state.profile?.id ?? await _patientId();
    if (id == null) return;
    emit(state.copyWith(saving: true, clearError: true, clearSuccess: true));
    final res = await repository.updateEmergencyContact(
      patientId: id,
      contact: contact,
    );
    res.fold(
      (f) => emit(state.copyWith(saving: false, errorMessage: f.message)),
      (p) => emit(
        state.copyWith(
          saving: false,
          profile: p,
          successMessage: 'Emergency contact saved.',
        ),
      ),
    );
  }

  Future<void> addInsurance({
    required String providerId,
    String? schemeId,
    required String policyNumber,
    String? memberNumber,
    DateTime? validFrom,
    DateTime? validTo,
    bool isPrimary = false,
  }) async {
    final id = state.profile?.id ?? await _patientId();
    if (id == null) return;
    emit(state.copyWith(saving: true, clearError: true, clearSuccess: true));
    final res = await repository.addInsurance(
      patientId: id,
      providerId: providerId,
      schemeId: schemeId,
      policyNumber: policyNumber,
      memberNumber: memberNumber,
      validFrom: validFrom,
      validTo: validTo,
      isPrimary: isPrimary,
    );
    res.fold(
      (f) => emit(state.copyWith(saving: false, errorMessage: f.message)),
      (p) => emit(
        state.copyWith(
          saving: false,
          profile: p,
          successMessage: 'Insurance added.',
        ),
      ),
    );
  }

  Future<void> removeInsurance(String insuranceId) async {
    final id = state.profile?.id ?? await _patientId();
    if (id == null) return;
    emit(state.copyWith(saving: true, clearError: true, clearSuccess: true));
    final res = await repository.removeInsurance(
      patientId: id,
      insuranceId: insuranceId,
    );
    res.fold(
      (f) => emit(state.copyWith(saving: false, errorMessage: f.message)),
      (p) => emit(
        state.copyWith(
          saving: false,
          profile: p,
          successMessage: 'Insurance removed.',
        ),
      ),
    );
  }

  Future<void> updateInsurance({
    required String insuranceId,
    required String providerName,
    required String policyNumber,
    String? memberNumber,
    DateTime? validFrom,
    DateTime? validTo,
    bool isPrimary = false,
  }) async {
    final id = state.profile?.id ?? await _patientId();
    if (id == null) return;
    emit(state.copyWith(saving: true, clearError: true, clearSuccess: true));
    final res = await repository.updateInsurance(
      patientId: id,
      insuranceId: insuranceId,
      providerName: providerName,
      policyNumber: policyNumber,
      memberNumber: memberNumber,
      validFrom: validFrom,
      validTo: validTo,
      isPrimary: isPrimary,
    );
    res.fold(
      (f) => emit(state.copyWith(saving: false, errorMessage: f.message)),
      (p) => emit(
        state.copyWith(
          saving: false,
          profile: p,
          successMessage: 'Insurance updated.',
        ),
      ),
    );
  }

  void clearMessages() {
    emit(state.copyWith(clearError: true, clearSuccess: true));
  }
}
