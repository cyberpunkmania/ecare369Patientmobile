import 'package:equatable/equatable.dart';

enum AppointmentStatus {
  Scheduled,
  CheckedIn,
  InConsultation,
  Completed,
  Cancelled,
  NoShow,
  Rescheduled;

  static AppointmentStatus fromString(String value) {
    return AppointmentStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => AppointmentStatus.Scheduled,
    );
  }
}

enum AppointmentChannel {
  Online,
  WalkIn,
  Reception,
  Emergency;

  static AppointmentChannel fromString(String value) {
    return AppointmentChannel.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => AppointmentChannel.Online,
    );
  }
}

enum AppointmentPaymentStatus {
  Pending,
  Paid,
  Waived,
  NotRequired,
  Refunded;

  static AppointmentPaymentStatus fromString(String value) {
    return AppointmentPaymentStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => AppointmentPaymentStatus.Pending,
    );
  }
}

class MyAppointmentDto extends Equatable {
  final String id;
  final String appointmentNumber;
  final String tenantId;
  final String branchId;
  final String patientId;
  final String patientName;
  final String outpatientNumber;
  final String? inpatientNumber;
  final String? patientPhone;
  final String doctorId;
  final String doctorName;
  final String doctorSpecialization;
  final String? slotId;
  final String appointmentDate;
  final String? startTime;
  final String? endTime;
  final String appointmentType;
  final String appointmentTypeLabel;
  final AppointmentChannel channel;
  final AppointmentStatus status;
  final AppointmentPaymentStatus paymentStatus;
  final double consultationFee;
  final String currency;
  final String? paymentMethod;
  final String? paymentReference;
  final String? paidAt;
  final String? reasonForVisit;
  final bool isEmergency;
  final String? previousVisitId;
  final String? checkedInAt;
  final String createdAt;
  final String? updatedAt;

  const MyAppointmentDto({
    required this.id,
    required this.appointmentNumber,
    required this.tenantId,
    required this.branchId,
    required this.patientId,
    required this.patientName,
    required this.outpatientNumber,
    this.inpatientNumber,
    this.patientPhone,
    required this.doctorId,
    required this.doctorName,
    required this.doctorSpecialization,
    this.slotId,
    required this.appointmentDate,
    this.startTime,
    this.endTime,
    this.appointmentType = 'Outpatient',
    this.appointmentTypeLabel = 'Outpatient',
    this.channel = AppointmentChannel.Online,
    this.status = AppointmentStatus.Scheduled,
    this.paymentStatus = AppointmentPaymentStatus.Pending,
    this.consultationFee = 0,
    this.currency = 'KES',
    this.paymentMethod,
    this.paymentReference,
    this.paidAt,
    this.reasonForVisit,
    this.isEmergency = false,
    this.previousVisitId,
    this.checkedInAt,
    required this.createdAt,
    this.updatedAt,
  });

  factory MyAppointmentDto.fromJson(Map<String, dynamic> json) {
    return MyAppointmentDto(
      id: json['id'] as String? ?? '',
      appointmentNumber: json['appointmentNumber'] as String? ?? '',
      tenantId: json['tenantId'] as String? ?? '',
      branchId: json['branchId'] as String? ?? '',
      patientId: json['patientId'] as String? ?? '',
      patientName: json['patientName'] as String? ?? '',
      outpatientNumber: json['outpatientNumber'] as String? ?? '',
      inpatientNumber: json['inpatientNumber'] as String?,
      patientPhone: json['patientPhone'] as String?,
      doctorId: json['doctorId'] as String? ?? '',
      doctorName: json['doctorName'] as String? ?? '',
      doctorSpecialization: json['doctorSpecialization'] as String? ?? '',
      slotId: json['slotId'] as String?,
      appointmentDate: json['appointmentDate'] as String? ?? '',
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      appointmentType: json['appointmentType'] as String? ?? 'Outpatient',
      appointmentTypeLabel:
          json['appointmentTypeLabel'] as String? ?? 'Outpatient',
      channel: AppointmentChannel.fromString(
        json['channel'] as String? ?? 'Online',
      ),
      status: AppointmentStatus.fromString(
        json['status'] as String? ?? 'Scheduled',
      ),
      paymentStatus: AppointmentPaymentStatus.fromString(
        json['paymentStatus'] as String? ?? 'Pending',
      ),
      consultationFee: (json['consultationFee'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'KES',
      paymentMethod: json['paymentMethod'] as String?,
      paymentReference: json['paymentReference'] as String?,
      paidAt: json['paidAt'] as String?,
      reasonForVisit: json['reasonForVisit'] as String?,
      isEmergency: json['isEmergency'] as bool? ?? false,
      previousVisitId: json['previousVisitId'] as String?,
      checkedInAt: json['checkedInAt'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'appointmentNumber': appointmentNumber,
    'tenantId': tenantId,
    'branchId': branchId,
    'patientId': patientId,
    'patientName': patientName,
    'outpatientNumber': outpatientNumber,
    'inpatientNumber': inpatientNumber,
    'patientPhone': patientPhone,
    'doctorId': doctorId,
    'doctorName': doctorName,
    'doctorSpecialization': doctorSpecialization,
    'slotId': slotId,
    'appointmentDate': appointmentDate,
    'startTime': startTime,
    'endTime': endTime,
    'appointmentType': appointmentType,
    'appointmentTypeLabel': appointmentTypeLabel,
    'channel': channel.name,
    'status': status.name,
    'paymentStatus': paymentStatus.name,
    'consultationFee': consultationFee,
    'currency': currency,
    'paymentMethod': paymentMethod,
    'paymentReference': paymentReference,
    'paidAt': paidAt,
    'reasonForVisit': reasonForVisit,
    'isEmergency': isEmergency,
    'previousVisitId': previousVisitId,
    'checkedInAt': checkedInAt,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  @override
  List<Object?> get props => [id, appointmentNumber, status];
}
