import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/public_tenant_entity.dart';
import '../repositories/tenant_repository.dart';

class GetPublicTenantsUseCase {
  final TenantRepository repository;

  GetPublicTenantsUseCase({required this.repository});

  Future<Either<Failure, List<PublicTenantEntity>>> call() {
    return repository.getPublicTenants();
  }
}
