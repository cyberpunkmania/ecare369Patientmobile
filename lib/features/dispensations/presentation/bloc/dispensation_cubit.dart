import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/secure_storage.dart';
import '../../domain/entities/dispensation_entity.dart';
import '../../domain/repositories/dispensation_repository.dart';

class DispensationState extends Equatable {
  final bool loading;
  final List<DispensationEntity> items;
  final String? errorMessage;

  const DispensationState({
    this.loading = false,
    this.items = const [],
    this.errorMessage,
  });

  DispensationState copyWith({
    bool? loading,
    List<DispensationEntity>? items,
    String? errorMessage,
    bool clearError = false,
  }) => DispensationState(
    loading: loading ?? this.loading,
    items: items ?? this.items,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );

  @override
  List<Object?> get props => [loading, items, errorMessage];
}

class DispensationCubit extends Cubit<DispensationState> {
  final DispensationRepository repository;
  // ignore: unused_field
  final SecureStorage secureStorage;

  DispensationCubit({required this.repository, required this.secureStorage})
    : super(const DispensationState());

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearError: true));
    final result = await repository.getDispensations();
    result.fold(
      (f) => emit(state.copyWith(loading: false, errorMessage: f.message)),
      (items) => emit(state.copyWith(loading: false, items: items)),
    );
  }
}
