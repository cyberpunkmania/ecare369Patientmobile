import 'package:equatable/equatable.dart';

enum SlotStatus {
  Available,
  OnHold,
  Booked,
  Blocked,
  Completed,
  NoShow,
  Expired;

  static SlotStatus fromString(String value) {
    return SlotStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SlotStatus.Blocked,
    );
  }
}

class AppointmentSlotDto extends Equatable {
  final String id;
  final String doctorId;
  final String branchId;
  final String date;
  final String startTime;
  final String endTime;
  final SlotStatus status;
  final bool allowOnlineBooking;
  final String? blockReason;
  final String? heldAt;
  final String? holdExpiresAt;

  const AppointmentSlotDto({
    required this.id,
    required this.doctorId,
    required this.branchId,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.status = SlotStatus.Available,
    this.allowOnlineBooking = true,
    this.blockReason,
    this.heldAt,
    this.holdExpiresAt,
  });

  bool get isBookable => status == SlotStatus.Available && allowOnlineBooking;

  /// True when the slot's start time is in the past (compared to [now]).
  /// Returns `false` if date / time can't be parsed.
  bool isPast(DateTime now) {
    try {
      final parts = startTime.split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final d = DateTime.parse(date);
      final slotStart = DateTime(d.year, d.month, d.day, h, m);
      return slotStart.isBefore(now);
    } catch (_) {
      return false;
    }
  }

  /// True when the slot is bookable right now — i.e. it's [isBookable] and
  /// not in the past.
  bool isBookableNow(DateTime now) => isBookable && !isPast(now);

  factory AppointmentSlotDto.fromJson(Map<String, dynamic> json) {
    return AppointmentSlotDto(
      id: json['id'] as String? ?? '',
      doctorId: json['doctorId'] as String? ?? '',
      branchId: json['branchId'] as String? ?? '',
      date: json['date'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      status: SlotStatus.fromString(json['status'] as String? ?? 'Blocked'),
      allowOnlineBooking: json['allowOnlineBooking'] as bool? ?? true,
      blockReason: json['blockReason'] as String?,
      heldAt: json['heldAt'] as String?,
      holdExpiresAt: json['holdExpiresAt'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, date, startTime, endTime, status];
}
