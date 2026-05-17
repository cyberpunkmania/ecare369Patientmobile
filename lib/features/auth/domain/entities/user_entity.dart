import 'package:equatable/equatable.dart';

/// User role DTO.
class UserRoleEntity extends Equatable {
  final String id;
  final String name;
  final String? description;

  const UserRoleEntity({
    required this.id,
    required this.name,
    this.description,
  });

  @override
  List<Object?> get props => [id, name, description];
}

/// Pure domain entity for an authenticated user.
/// Matches the UserDto from the backend.
class UserEntity extends Equatable {
  final String id;
  final String? tenantId;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String email;
  final String phoneNumber;
  final bool isActive;
  final DateTime? lastLoginAt;
  final bool emailConfirmed;
  final List<UserRoleEntity> roles;
  final List<String> permissions;

  // Additional fields from JWT claims
  final String? patientId;
  final String? doctorId;
  final String? branchId;
  final String? departmentId;

  const UserEntity({
    required this.id,
    this.tenantId,
    required this.firstName,
    required this.lastName,
    this.middleName,
    required this.email,
    required this.phoneNumber,
    this.isActive = true,
    this.lastLoginAt,
    this.emailConfirmed = false,
    this.roles = const [],
    this.permissions = const [],
    this.patientId,
    this.doctorId,
    this.branchId,
    this.departmentId,
  });

  /// Full name computed from first, middle, and last name.
  String get fullName {
    if (middleName != null && middleName!.isNotEmpty) {
      return '$firstName ${middleName![0]}. $lastName';
    }
    return '$firstName $lastName';
  }

  /// Alias for backwards compatibility.
  String get name => fullName;

  /// Alias for backwards compatibility.
  String? get phone => phoneNumber;

  /// Check if user has a specific role.
  bool hasRole(String roleName) =>
      roles.any((r) => r.name.toLowerCase() == roleName.toLowerCase());

  /// Check if user has a specific permission.
  bool hasPermission(String permission) => permissions.contains(permission);

  /// Whether the user is a patient.
  bool get isPatient => patientId != null;

  /// Whether the user is a doctor.
  bool get isDoctor => doctorId != null;

  /// Primary role name for display.
  String get primaryRole {
    if (roles.isEmpty) return 'Patient';
    return roles.first.name;
  }

  @override
  List<Object?> get props => [
    id,
    tenantId,
    firstName,
    lastName,
    middleName,
    email,
    phoneNumber,
    isActive,
    lastLoginAt,
    emailConfirmed,
    roles,
    permissions,
    patientId,
    doctorId,
    branchId,
    departmentId,
  ];
}
