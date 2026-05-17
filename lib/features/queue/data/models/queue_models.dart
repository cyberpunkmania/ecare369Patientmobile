import '../../domain/entities/queue_entities.dart';

class QueueLiveSnapshotModel extends QueueLiveSnapshotEntity {
  const QueueLiveSnapshotModel({
    required super.branchId,
    required super.waitingCount,
    required super.inServiceCount,
    required super.counters,
    required super.fetchedAt,
  });

  factory QueueLiveSnapshotModel.fromJson(
    Map<String, dynamic> json,
    String branchId,
  ) {
    final countersJson = json['counters'] ?? json['doctors'];
    final counters = (countersJson is List)
        ? countersJson
              .whereType<Map<String, dynamic>>()
              .map(QueueCounterModel.fromJson)
              .toList()
        : <QueueCounterModel>[];
    return QueueLiveSnapshotModel(
      branchId: json['branchId']?.toString() ?? branchId,
      waitingCount: (json['waitingCount'] as num?)?.toInt() ?? 0,
      inServiceCount: (json['inServiceCount'] as num?)?.toInt() ?? 0,
      counters: counters,
      fetchedAt: DateTime.now(),
    );
  }
}

class QueueCounterModel extends QueueCounterEntity {
  const QueueCounterModel({
    required super.doctorName,
    required super.waiting,
    super.doctorId,
    super.currentPatientName,
  });

  factory QueueCounterModel.fromJson(Map<String, dynamic> json) =>
      QueueCounterModel(
        doctorId: json['doctorId']?.toString(),
        doctorName: json['doctorName']?.toString() ?? 'Doctor',
        currentPatientName: json['currentPatientName']?.toString(),
        waiting: (json['waiting'] as num?)?.toInt() ?? 0,
      );
}

class QueuePositionModel extends QueuePositionEntity {
  const QueuePositionModel({
    required super.position,
    required super.status,
    super.appointmentId,
    super.etaMinutes,
    super.doctorName,
  });

  factory QueuePositionModel.fromJson(Map<String, dynamic> json) =>
      QueuePositionModel(
        appointmentId: json['appointmentId']?.toString(),
        position: (json['position'] as num?)?.toInt() ?? 0,
        etaMinutes: (json['etaMinutes'] as num?)?.toInt(),
        doctorName: json['doctorName']?.toString(),
        status: json['status']?.toString() ?? 'unknown',
      );
}
