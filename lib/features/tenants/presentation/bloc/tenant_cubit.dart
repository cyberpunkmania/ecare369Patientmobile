import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/secure_storage.dart';
import '../../domain/entities/public_tenant_entity.dart';
import '../../domain/usecases/get_public_tenants_usecase.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  State
// ─────────────────────────────────────────────────────────────────────────────

class TenantState extends Equatable {
  final bool loading;
  final List<PublicTenantEntity> tenants;
  final String? errorMessage;
  final String? selectedTenantId;
  final String query;

  const TenantState({
    this.loading = false,
    this.tenants = const [],
    this.errorMessage,
    this.selectedTenantId,
    this.query = '',
  });

  /// Tenants filtered by [query] (case-insensitive substring on name/code).
  List<PublicTenantEntity> get visibleTenants {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return tenants;
    return tenants
        .where(
          (t) =>
              t.name.toLowerCase().contains(q) ||
              t.code.toLowerCase().contains(q),
        )
        .toList(growable: false);
  }

  PublicTenantEntity? get selectedTenant {
    if (selectedTenantId == null) return null;
    for (final t in tenants) {
      if (t.id == selectedTenantId) return t;
    }
    return null;
  }

  TenantState copyWith({
    bool? loading,
    List<PublicTenantEntity>? tenants,
    String? errorMessage,
    bool clearError = false,
    String? selectedTenantId,
    bool clearSelection = false,
    String? query,
  }) {
    return TenantState(
      loading: loading ?? this.loading,
      tenants: tenants ?? this.tenants,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedTenantId: clearSelection
          ? null
          : (selectedTenantId ?? this.selectedTenantId),
      query: query ?? this.query,
    );
  }

  @override
  List<Object?> get props => [
    loading,
    tenants,
    errorMessage,
    selectedTenantId,
    query,
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
//  Cubit
// ─────────────────────────────────────────────────────────────────────────────

/// Drives the "Select your clinic group" screen.
///
/// Persists the chosen tenant id to [SecureStorage] under the existing
/// `tenant_id` key so [AuthInterceptor] picks it up on every subsequent
/// request via the `X-Tenant-ID` header.
class TenantCubit extends Cubit<TenantState> {
  final GetPublicTenantsUseCase _getPublicTenants;
  final SecureStorage _secureStorage;

  TenantCubit({
    required GetPublicTenantsUseCase getPublicTenants,
    required SecureStorage secureStorage,
  }) : _getPublicTenants = getPublicTenants,
       _secureStorage = secureStorage,
       super(const TenantState());

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearError: true));

    final result = await _getPublicTenants();
    final preselected = await _secureStorage.getTenantId();

    result.fold(
      (failure) =>
          emit(state.copyWith(loading: false, errorMessage: failure.message)),
      (list) => emit(
        state.copyWith(
          loading: false,
          tenants: list,
          selectedTenantId: preselected != null && preselected.isNotEmpty
              ? preselected
              : null,
        ),
      ),
    );
  }

  void search(String query) => emit(state.copyWith(query: query));

  void select(String tenantId) =>
      emit(state.copyWith(selectedTenantId: tenantId));

  /// Persists the current selection so [AuthInterceptor] can attach
  /// `X-Tenant-ID` to subsequent requests. Returns the selected entity, or
  /// null if nothing is selected.
  Future<PublicTenantEntity?> confirmSelection() async {
    final selected = state.selectedTenant;
    if (selected == null) return null;
    await _secureStorage.saveTenantId(selected.id);
    return selected;
  }
}
