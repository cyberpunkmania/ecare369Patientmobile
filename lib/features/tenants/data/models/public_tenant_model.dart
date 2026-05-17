import '../../domain/entities/public_tenant_entity.dart';

class PublicTenantModel extends PublicTenantEntity {
  const PublicTenantModel({
    required super.id,
    required super.name,
    required super.code,
    required super.type,
    super.logoUrl,
    required super.hasMultipleBranches,
  });

  factory PublicTenantModel.fromJson(Map<String, dynamic> json) {
    return PublicTenantModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      type: json['type'] as String? ?? '',
      logoUrl: json['logoUrl'] as String?,
      hasMultipleBranches: json['hasMultipleBranches'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'type': type,
    'logoUrl': logoUrl,
    'hasMultipleBranches': hasMultipleBranches,
  };
}
