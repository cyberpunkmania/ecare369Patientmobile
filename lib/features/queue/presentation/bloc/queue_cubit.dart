import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/realtime/signalr_service.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/entities/queue_entities.dart';
import '../../domain/repositories/queue_repository.dart';

class QueueState extends Equatable {
  final bool loading;
  final QueueLiveSnapshotEntity? snapshot;
  final QueuePositionEntity? myPosition;
  final String? errorMessage;
  final DateTime? lastUpdatedAt;

  const QueueState({
    this.loading = false,
    this.snapshot,
    this.myPosition,
    this.errorMessage,
    this.lastUpdatedAt,
  });

  const QueueState.initial() : this();

  QueueState copyWith({
    bool? loading,
    QueueLiveSnapshotEntity? snapshot,
    QueuePositionEntity? myPosition,
    String? errorMessage,
    DateTime? lastUpdatedAt,
    bool clearError = false,
  }) => QueueState(
    loading: loading ?? this.loading,
    snapshot: snapshot ?? this.snapshot,
    myPosition: myPosition ?? this.myPosition,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
  );

  @override
  List<Object?> get props => [
    loading,
    snapshot,
    myPosition,
    errorMessage,
    lastUpdatedAt,
  ];
}

class QueueCubit extends Cubit<QueueState> {
  final QueueRepository repository;
  final SecureStorage secureStorage;
  final SignalRService signalR;

  StreamSubscription<QueueUpdatedEvent>? _queueSub;
  StreamSubscription<PatientCalledEvent>? _calledSub;
  String? _branchId;

  QueueCubit({
    required this.repository,
    required this.secureStorage,
    required this.signalR,
  }) : super(const QueueState.initial());

  Future<void> load({String? branchId}) async {
    final id = branchId ?? _branchId;
    if (id == null || id.isEmpty) {
      emit(
        state.copyWith(
          errorMessage: 'No branch selected for the queue view.',
          loading: false,
        ),
      );
      return;
    }
    _branchId = id;
    emit(state.copyWith(loading: true, clearError: true));

    final patientId = await secureStorage.getPatientId() ?? '';
    final snapshot = await repository.getLiveSnapshot(id);
    final position = patientId.isEmpty
        ? null
        : await repository.getMyPosition(branchId: id, patientId: patientId);

    snapshot.fold(
      (f) => emit(state.copyWith(loading: false, errorMessage: f.message)),
      (snap) => emit(
        state.copyWith(
          loading: false,
          snapshot: snap,
          myPosition: position?.fold((_) => null, (p) => p) ?? state.myPosition,
          lastUpdatedAt: DateTime.now(),
        ),
      ),
    );

    await _subscribe(id);
  }

  Future<void> _subscribe(String branchId) async {
    try {
      await signalR.ensureStarted();
    } catch (_) {
      // Live updates remain unavailable; polling fallback is acceptable.
      return;
    }
    await _queueSub?.cancel();
    await _calledSub?.cancel();
    _queueSub = signalR.queueUpdates.listen((evt) {
      if (evt.branchId != branchId) return;
      final snap = state.snapshot;
      if (snap == null) return;
      emit(
        state.copyWith(
          snapshot: QueueLiveSnapshotEntity(
            branchId: snap.branchId,
            waitingCount: evt.waitingCount,
            inServiceCount: evt.inServiceCount,
            counters: snap.counters,
            fetchedAt: DateTime.now(),
          ),
          lastUpdatedAt: DateTime.now(),
        ),
      );
    });
    _calledSub = signalR.patientCalled.listen((_) {
      // Trigger a position refresh.
      load(branchId: branchId);
    });
  }

  @override
  Future<void> close() async {
    await _queueSub?.cancel();
    await _calledSub?.cancel();
    return super.close();
  }
}
