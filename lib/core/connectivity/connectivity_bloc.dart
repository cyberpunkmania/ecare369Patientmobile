import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../network/network_info.dart';

// ── Events ──
abstract class ConnectivityEvent extends Equatable {
  const ConnectivityEvent();
  @override
  List<Object?> get props => [];
}

class ConnectivityStarted extends ConnectivityEvent {}

class _ConnectivityChanged extends ConnectivityEvent {
  final List<ConnectivityResult> results;
  const _ConnectivityChanged(this.results);
  @override
  List<Object?> get props => [results];
}

// ── States ──
abstract class ConnectivityState extends Equatable {
  const ConnectivityState();
  @override
  List<Object?> get props => [];
}

class ConnectivityInitial extends ConnectivityState {}

class ConnectivityOnline extends ConnectivityState {}

class ConnectivityOffline extends ConnectivityState {}

// ── Bloc ──
class ConnectivityBloc extends Bloc<ConnectivityEvent, ConnectivityState> {
  final NetworkInfo _networkInfo;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  ConnectivityBloc({required NetworkInfo networkInfo})
    : _networkInfo = networkInfo,
      super(ConnectivityInitial()) {
    on<ConnectivityStarted>(_onStarted);
    on<_ConnectivityChanged>(_onChanged);
  }

  Future<void> _onStarted(
    ConnectivityStarted event,
    Emitter<ConnectivityState> emit,
  ) async {
    _subscription?.cancel();
    _subscription = _networkInfo.onConnectivityChanged.listen(
      (results) => add(_ConnectivityChanged(results)),
    );

    // Emit initial state.
    final connected = await _networkInfo.isConnected;
    emit(connected ? ConnectivityOnline() : ConnectivityOffline());
  }

  Future<void> _onChanged(
    _ConnectivityChanged event,
    Emitter<ConnectivityState> emit,
  ) async {
    final hasNone = event.results.contains(ConnectivityResult.none);
    if (hasNone) {
      emit(ConnectivityOffline());
    } else {
      final connected = await _networkInfo.isConnected;
      emit(connected ? ConnectivityOnline() : ConnectivityOffline());
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
