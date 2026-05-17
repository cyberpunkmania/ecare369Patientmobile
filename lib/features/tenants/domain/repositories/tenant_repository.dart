import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/public_tenant_entity.dart';

abstract class TenantRepository {
  /// Returns the list of active tenants (branding-only fields).
  Future<Either<Failure, List<PublicTenantEntity>>> getPublicTenants();
}
