import 'package:equatable/equatable.dart';

/// Live snapshot of a single branch's queue. Mirrors the response of
/// `GET /api/queues/branch/{branchId}/live`.
class QueueLiveSnapshotEntity extends Equatable {
  final String branchId;
  final int waitingCount;
  final int inServiceCount;
  final List<QueueCounterEntity> counters;
  final DateTime fetchedAt;

  const QueueLiveSnapshotEntity({
    required this.branchId,
    required this.waitingCount,
    required this.inServiceCount,
    required this.counters,
    required this.fetchedAt,
  });

  @override
  List<Object?> get props => [
    branchId,
    waitingCount,
    inServiceCount,
    counters,
    fetchedAt,
  ];
}

class QueueCounterEntity extends Equatable {
  final String? doctorId;
  final String doctorName;
  final String? currentPatientName;
  final int waiting;

  const QueueCounterEntity({
    required this.doctorName,
    required this.waiting,
    this.doctorId,
    this.currentPatientName,
  });

  @override
  List<Object?> get props => [
    doctorId,
    doctorName,
    currentPatientName,
    waiting,
  ];
}

class QueuePositionEntity extends Equatable {
  final String? appointmentId;
  final int position;
  final int? etaMinutes;
  final String? doctorName;
  final String status;

  const QueuePositionEntity({
    required this.position,
    required this.status,
    this.appointmentId,
    this.etaMinutes,
    this.doctorName,
  });

  @override
  List<Object?> get props => [
    appointmentId,
    position,
    etaMinutes,
    doctorName,
    status,
  ];
}
