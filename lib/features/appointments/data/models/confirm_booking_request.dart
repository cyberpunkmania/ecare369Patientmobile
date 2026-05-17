class ConfirmBookingRequest {
  final String slotId;
  final String scheduleId;
  final String appointmentDate;
  final String startTime;
  final String endTime;
  final String tenantId;
  final String branchId;
  final String patientId;
  final String patientName;
  final String outpatientNumber;
  final String? patientPhone;
  final String doctorId;
  final String doctorName;
  final String doctorSpecialization;
  final double consultationFee;
  final String? currency;
  final String? reasonForVisit;
  final String? appointmentTypeLabel;
  final String? previousVisitId;

  const ConfirmBookingRequest({
    required this.slotId,
    required this.scheduleId,
    required this.appointmentDate,
    required this.startTime,
    required this.endTime,
    required this.tenantId,
    required this.branchId,
    required this.patientId,
    required this.patientName,
    required this.outpatientNumber,
    this.patientPhone,
    required this.doctorId,
    required this.doctorName,
    required this.doctorSpecialization,
    required this.consultationFee,
    this.currency,
    this.reasonForVisit,
    this.appointmentTypeLabel,
    this.previousVisitId,
  });

  Map<String, dynamic> toJson() {
    return {
      'slotId': slotId,
      'scheduleId': scheduleId,
      'appointmentDate': appointmentDate,
      'startTime': startTime,
      'endTime': endTime,
      'tenantId': tenantId,
      'branchId': branchId,
      'patientId': patientId,
      'patientName': patientName,
      'outpatientNumber': outpatientNumber,
      if (patientPhone != null) 'patientPhone': patientPhone,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'doctorSpecialization': doctorSpecialization,
      'consultationFee': consultationFee,
      if (currency != null) 'currency': currency,
      if (reasonForVisit != null && reasonForVisit!.isNotEmpty)
        'reasonForVisit': reasonForVisit,
      if (appointmentTypeLabel != null)
        'appointmentTypeLabel': appointmentTypeLabel,
      if (previousVisitId != null) 'previousVisitId': previousVisitId,
    };
  }
}
