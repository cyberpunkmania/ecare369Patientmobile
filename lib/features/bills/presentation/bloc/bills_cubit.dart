import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/secure_storage.dart';
import '../../domain/entities/bill_entity.dart';
import '../../domain/repositories/bill_repository.dart';

class BillsState extends Equatable {
  final bool loading;
  final bool loadingDetail;
  final List<BillEntity> bills;
  final BillEntity? selected;
  final String? errorMessage;

  const BillsState({
    this.loading = false,
    this.loadingDetail = false,
    this.bills = const [],
    this.selected,
    this.errorMessage,
  });

  BillsState copyWith({
    bool? loading,
    bool? loadingDetail,
    List<BillEntity>? bills,
    BillEntity? selected,
    String? errorMessage,
    bool clearError = false,
    bool clearSelected = false,
  }) => BillsState(
    loading: loading ?? this.loading,
    loadingDetail: loadingDetail ?? this.loadingDetail,
    bills: bills ?? this.bills,
    selected: clearSelected ? null : (selected ?? this.selected),
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );

  @override
  List<Object?> get props => [
    loading,
    loadingDetail,
    bills,
    selected,
    errorMessage,
  ];
}

class BillsCubit extends Cubit<BillsState> {
  final BillRepository repository;
  // ignore: unused_field
  final SecureStorage secureStorage;

  BillsCubit({required this.repository, required this.secureStorage})
    : super(const BillsState());

  Future<void> loadList() async {
    emit(state.copyWith(loading: true, clearError: true));
    final res = await repository.getBills();
    res.fold(
      (f) => emit(state.copyWith(loading: false, errorMessage: f.message)),
      (bills) => emit(state.copyWith(loading: false, bills: bills)),
    );
  }

  Future<void> loadDetail(String id) async {
    emit(state.copyWith(loadingDetail: true, clearError: true));
    final res = await repository.getBillById(id);
    res.fold(
      (f) =>
          emit(state.copyWith(loadingDetail: false, errorMessage: f.message)),
      (b) => emit(state.copyWith(loadingDetail: false, selected: b)),
    );
  }
}
