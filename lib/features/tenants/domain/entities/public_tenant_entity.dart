import 'package:equatable/equatable.dart';

/// Branding-level projection of a tenant returned by `GET /api/tenants/public`.
/// Used by self-registration UIs to let a prospective patient pick their
/// clinic-group before creating an account.
class PublicTenantEntity extends Equatable {
  final String id;
  final String name;
  final String code;
  final String type;
  final String? logoUrl;
  final bool hasMultipleBranches;

  const PublicTenantEntity({
    required this.id,
    required this.name,
    required this.code,
    required this.type,
    this.logoUrl,
    required this.hasMultipleBranches,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    code,
    type,
    logoUrl,
    hasMultipleBranches,
  ];
}
