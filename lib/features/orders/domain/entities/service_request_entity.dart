import 'package:equatable/equatable.dart';

class ServiceRequestEntity extends Equatable {
  final String id;
  final String appointmentId;
  final String? consultationId;
  final String? admissionId;
  final String category;
  final String serviceCode;
  final String serviceName;
  final String description;
  final num unitPrice;
  final int quantity;
  final num totalAmount;
  final String currencyCode;

  /// Lifecycle: Requested | Approved | InProgress | Completed | Cancelled
  final String status;

  /// Payment: PendingAssessment | CopayRequired | FullyCovered | Approved | Waived
  final String paymentStatus;
  final num patientCopayAmount;
  final num insuranceCoveredAmount;

  final String requestedByName;
  final DateTime requestedAt;
  final String? notes;

  // Results (populated when status == Completed)
  final String? resultSummary;
  final String? resultFileUrl;
  final String? resultNotes;
  final List<ServiceRequestAttachmentEntity> attachments;

  final DateTime? executedAt;
  final DateTime? completedAt;

  const ServiceRequestEntity({
    required this.id,
    required this.appointmentId,
    this.consultationId,
    this.admissionId,
    required this.category,
    required this.serviceCode,
    required this.serviceName,
    required this.description,
    required this.unitPrice,
    required this.quantity,
    required this.totalAmount,
    required this.currencyCode,
    required this.status,
    required this.paymentStatus,
    required this.patientCopayAmount,
    required this.insuranceCoveredAmount,
    required this.requestedByName,
    required this.requestedAt,
    this.notes,
    this.resultSummary,
    this.resultFileUrl,
    this.resultNotes,
    this.attachments = const [],
    this.executedAt,
    this.completedAt,
  });

  bool get isCompleted => status == 'Completed';
  bool get isCancelled => status == 'Cancelled';
  bool get hasResults =>
      resultSummary != null || resultFileUrl != null || attachments.isNotEmpty;
  bool get isLab => category == 'Lab';
  bool get isRadiology => category == 'Radiology';

  @override
  List<Object?> get props => [
    id,
    appointmentId,
    category,
    serviceName,
    status,
    paymentStatus,
    requestedAt,
    completedAt,
  ];
}

class ServiceRequestAttachmentEntity extends Equatable {
  final String id;
  final String originalFileName;
  final String contentType;
  final int fileSizeBytes;
  final String? downloadUrl;
  final DateTime uploadedAt;

  const ServiceRequestAttachmentEntity({
    required this.id,
    required this.originalFileName,
    required this.contentType,
    required this.fileSizeBytes,
    this.downloadUrl,
    required this.uploadedAt,
  });

  bool get isImage => contentType.startsWith('image/');

  bool get isPdf => contentType == 'application/pdf';

  @override
  List<Object?> get props => [id, originalFileName, downloadUrl];
}
