import 'package:equatable/equatable.dart';

/// Bookable doctor entry shown in the booking wizard's doctor list.
///
/// Sourced from one of two backend endpoints:
///
/// 1. **Tenant-scoped active doctor list** – `GET /api/doctors?status=Active`
///    (the same call the web frontend uses). Returned items don't carry a
///    `scheduleId` upfront — the cubit resolves it lazily on selection via
///    `GET /api/schedules/doctor/{doctorId}/branch/{branchId}`.
///
/// 2. **Branch-availability list** (legacy) – `GET /api/schedules/branch/
///    {branchId}/available-doctors?date=…` – already aggregates `scheduleId`,
///    `availableSlotCount`, and `nextAvailableSlot`.
class DoctorAvailabilityDto extends Equatable {
  final String doctorId;

  /// May be empty when sourced from `/api/doctors` listing — the cubit
  /// resolves it on selection.
  final String scheduleId;

  /// Branch the doctor practices at. Required to resolve the schedule.
  /// Empty when unknown.
  final String branchId;

  final String doctorName;
  final String specialization;
  final String specialty;
  final String? profilePhotoUrl;
  final String? nextAvailableSlot;
  final int availableSlotCount;
  final bool isAtCapacity;
  final double consultationFee;
  final String currency;
  final String availabilityStatus;

  /// Optional clinical bio shown on the doctor card / detail view.
  final String? biography;

  /// Years of experience (0 if unknown).
  final int yearsOfExperience;

  const DoctorAvailabilityDto({
    required this.doctorId,
    required this.scheduleId,
    required this.doctorName,
    required this.specialization,
    required this.specialty,
    this.branchId = '',
    this.profilePhotoUrl,
    this.nextAvailableSlot,
    this.availableSlotCount = 0,
    this.isAtCapacity = false,
    this.consultationFee = 0,
    this.currency = 'KES',
    this.availabilityStatus = 'Available',
    this.biography,
    this.yearsOfExperience = 0,
  });

  /// Creates a copy with overrides — used by the cubit to attach the
  /// resolved `scheduleId` after selection.
  DoctorAvailabilityDto copyWith({String? scheduleId, String? branchId}) {
    return DoctorAvailabilityDto(
      doctorId: doctorId,
      scheduleId: scheduleId ?? this.scheduleId,
      branchId: branchId ?? this.branchId,
      doctorName: doctorName,
      specialization: specialization,
      specialty: specialty,
      profilePhotoUrl: profilePhotoUrl,
      nextAvailableSlot: nextAvailableSlot,
      availableSlotCount: availableSlotCount,
      isAtCapacity: isAtCapacity,
      consultationFee: consultationFee,
      currency: currency,
      availabilityStatus: availabilityStatus,
      biography: biography,
      yearsOfExperience: yearsOfExperience,
    );
  }

  /// Parses the legacy `available-doctors` shape (pre-aggregated for booking).
  factory DoctorAvailabilityDto.fromJson(Map<String, dynamic> json) {
    return DoctorAvailabilityDto(
      doctorId: json['doctorId'] as String? ?? '',
      scheduleId: json['scheduleId'] as String? ?? '',
      branchId: json['branchId'] as String? ?? '',
      doctorName: json['doctorName'] as String? ?? '',
      specialization: json['specialization'] as String? ?? '',
      specialty: json['specialty'] as String? ?? '',
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      nextAvailableSlot: json['nextAvailableSlot'] as String?,
      availableSlotCount: json['availableSlotCount'] as int? ?? 0,
      isAtCapacity: json['isAtCapacity'] as bool? ?? false,
      consultationFee: (json['consultationFee'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'KES',
      availabilityStatus: json['availabilityStatus'] as String? ?? 'Available',
    );
  }

  /// Parses an item from `GET /api/doctors?status=Active` (the same call
  /// the web frontend uses). Schedule resolution is deferred to selection.
  factory DoctorAvailabilityDto.fromDoctorListing(Map<String, dynamic> json) {
    final firstName = (json['firstName'] as String?)?.trim() ?? '';
    final lastName = (json['lastName'] as String?)?.trim() ?? '';
    final composedName = ('$firstName $lastName').trim();
    final fullName = (json['fullName'] as String?)?.trim();
    final name = (fullName != null && fullName.isNotEmpty)
        ? fullName
        : (composedName.isEmpty ? 'Doctor' : composedName);

    // Pick the first active tenant assignment to derive branchId.
    String resolvedBranchId = '';
    final assignments = json['tenantAssignments'];
    if (assignments is List) {
      for (final a in assignments) {
        if (a is Map<String, dynamic>) {
          final status = (a['status'] as String?)?.toLowerCase() ?? '';
          if (status.isEmpty || status == 'active') {
            resolvedBranchId = (a['branchId'] as String?) ?? '';
            if (resolvedBranchId.isNotEmpty) break;
          }
        }
      }
    }

    final primarySpecialty = (json['primarySpecialty'] as String?) ?? '';

    return DoctorAvailabilityDto(
      doctorId: json['id'] as String? ?? '',
      scheduleId: '', // resolved lazily on selection
      branchId: resolvedBranchId,
      doctorName: name,
      specialization: _humanizeSpecialty(primarySpecialty),
      specialty: primarySpecialty,
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      consultationFee: (json['consultationFee'] as num?)?.toDouble() ?? 0,
      currency: (json['currency'] as String?) ?? 'KES',
      biography: json['biography'] as String?,
      yearsOfExperience: (json['yearsOfExperience'] as num?)?.toInt() ?? 0,
    );
  }

  /// Inserts spaces before capitals: "FamilyMedicine" → "Family Medicine".
  static String _humanizeSpecialty(String raw) {
    if (raw.isEmpty) return '';
    final buf = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      final c = raw[i];
      if (i > 0 &&
          c.toUpperCase() == c &&
          c.toLowerCase() != c &&
          raw[i - 1].toLowerCase() == raw[i - 1]) {
        buf.write(' ');
      }
      buf.write(c);
    }
    return buf.toString();
  }

  @override
  List<Object?> get props => [doctorId, scheduleId, doctorName];
}
