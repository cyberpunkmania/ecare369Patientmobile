import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/service_request_entity.dart';

abstract class OrdersRepository {
  Future<Either<Failure, List<ServiceRequestEntity>>> getOrdersByAppointment(
    String appointmentId,
  );

  Future<Either<Failure, ServiceRequestEntity>> getOrderById(String orderId);
}
