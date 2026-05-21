import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/service_request_entity.dart';
import '../../domain/repositories/orders_repository.dart';

// ─── State ───────────────────────────────────────────────────────────────────

enum OrdersStatus { initial, loading, loaded, error }

class OrdersState extends Equatable {
  final OrdersStatus status;
  final List<ServiceRequestEntity> orders;
  final ServiceRequestEntity? selectedOrder;
  final String? errorMessage;

  const OrdersState({
    this.status = OrdersStatus.initial,
    this.orders = const [],
    this.selectedOrder,
    this.errorMessage,
  });

  OrdersState copyWith({
    OrdersStatus? status,
    List<ServiceRequestEntity>? orders,
    ServiceRequestEntity? selectedOrder,
    String? errorMessage,
  }) => OrdersState(
    status: status ?? this.status,
    orders: orders ?? this.orders,
    selectedOrder: selectedOrder ?? this.selectedOrder,
    errorMessage: errorMessage ?? this.errorMessage,
  );

  /// Orders grouped by category label for UI display.
  Map<String, List<ServiceRequestEntity>> get grouped {
    final map = <String, List<ServiceRequestEntity>>{};
    for (final o in orders) {
      map.putIfAbsent(o.category, () => []).add(o);
    }
    return map;
  }

  @override
  List<Object?> get props => [status, orders, selectedOrder, errorMessage];
}

// ─── Cubit ───────────────────────────────────────────────────────────────────

class OrdersCubit extends Cubit<OrdersState> {
  final OrdersRepository _repository;

  OrdersCubit({required OrdersRepository repository})
    : _repository = repository,
      super(const OrdersState());

  Future<void> loadByAppointment(String appointmentId) async {
    emit(state.copyWith(status: OrdersStatus.loading));

    final result = await _repository.getOrdersByAppointment(appointmentId);

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: OrdersStatus.error,
          errorMessage: failure.message ?? 'Unable to load orders',
        ),
      ),
      (orders) =>
          emit(state.copyWith(status: OrdersStatus.loaded, orders: orders)),
    );
  }

  Future<void> loadDetail(String orderId) async {
    emit(state.copyWith(status: OrdersStatus.loading));

    final result = await _repository.getOrderById(orderId);

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: OrdersStatus.error,
          errorMessage: failure.message ?? 'Unable to load order detail',
        ),
      ),
      (order) => emit(
        state.copyWith(status: OrdersStatus.loaded, selectedOrder: order),
      ),
    );
  }
}
