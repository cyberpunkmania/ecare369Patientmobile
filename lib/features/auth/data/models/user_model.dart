import '../../domain/entities/user_entity.dart';

/// Data model for UserRoleDto.
class UserRoleModel extends UserRoleEntity {
  const UserRoleModel({
    required super.id,
    required super.name,
    super.description,
  });

  factory UserRoleModel.fromJson(Map<String, dynamic> json) {
    return UserRoleModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
    );
  }

  /// Create from plain string (when roles are returned as string[]).
  factory UserRoleModel.fromString(String roleName) {
    return UserRoleModel(id: roleName, name: roleName);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'description': description};
  }
}

/// Data model for UserDto from the API.
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    super.tenantId,
    required super.firstName,
    required super.lastName,
    super.middleName,
    required super.email,
    required super.phoneNumber,
    super.isActive,
    super.lastLoginAt,
    super.emailConfirmed,
    super.roles,
    super.permissions,
    super.patientId,
    super.doctorId,
    super.branchId,
    super.departmentId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Handle roles - can be list of objects or list of strings
    final rolesRaw = json['roles'] as List<dynamic>?;
    final roles =
        rolesRaw?.map<UserRoleModel>((e) {
          if (e is Map<String, dynamic>) {
            return UserRoleModel.fromJson(e);
          } else if (e is String) {
            return UserRoleModel.fromString(e);
          }
          return UserRoleModel.fromString(e.toString());
        }).toList() ??
        [];

    // Handle permissions
    final permissionsRaw = json['permissions'] as List<dynamic>?;
    final permissions = permissionsRaw?.map((e) => e.toString()).toList() ?? [];

    // Handle lastLoginAt
    DateTime? lastLoginAt;
    final lastLoginAtRaw = json['lastLoginAt'];
    if (lastLoginAtRaw != null && lastLoginAtRaw is String) {
      lastLoginAt = DateTime.tryParse(lastLoginAtRaw);
    }

    // Legacy name field support
    final name = json['name'] as String? ?? json['fullName'] as String?;
    String firstName;
    String lastName;
    String? middleName;

    if (json['firstName'] != null) {
      firstName = json['firstName'] as String? ?? '';
      lastName = json['lastName'] as String? ?? '';
      middleName = json['middleName'] as String?;
    } else if (name != null) {
      // Parse from full name
      final parts = name.trim().split(' ');
      firstName = parts.isNotEmpty ? parts.first : '';
      lastName = parts.length > 1 ? parts.last : '';
      middleName = parts.length > 2
          ? parts.sublist(1, parts.length - 1).join(' ')
          : null;
    } else {
      firstName = '';
      lastName = '';
    }

    return UserModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      tenantId: json['tenantId'] as String? ?? json['tenant_id'] as String?,
      firstName: firstName,
      lastName: lastName,
      middleName: middleName,
      email: json['email'] as String? ?? '',
      phoneNumber:
          json['phoneNumber'] as String? ?? json['phone'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      lastLoginAt: lastLoginAt,
      emailConfirmed: json['emailConfirmed'] as bool? ?? false,
      roles: roles,
      permissions: permissions,
      patientId: json['patientId'] as String? ?? json['patient_id'] as String?,
      doctorId: json['doctorId'] as String? ?? json['doctor_id'] as String?,
      branchId: json['defaultBranchId'] as String? ??
          json['branchId'] as String? ??
          json['branch_id'] as String?,
      departmentId:
          json['departmentId'] as String? ?? json['department_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenantId': tenantId,
      'firstName': firstName,
      'lastName': lastName,
      'middleName': middleName,
      'email': email,
      'phoneNumber': phoneNumber,
      'isActive': isActive,
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'emailConfirmed': emailConfirmed,
      'roles': roles.map((e) => (e as UserRoleModel).toJson()).toList(),
      'permissions': permissions,
      'patientId': patientId,
      'doctorId': doctorId,
      'branchId': branchId,
      'departmentId': departmentId,
    };
  }
}
