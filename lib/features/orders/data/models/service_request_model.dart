import '../../domain/entities/service_request_entity.dart';

class ServiceRequestAttachmentModel extends ServiceRequestAttachmentEntity {
  const ServiceRequestAttachmentModel({
    required super.id,
    required super.originalFileName,
    required super.contentType,
    required super.fileSizeBytes,
    super.downloadUrl,
    required super.uploadedAt,
  });

  factory ServiceRequestAttachmentModel.fromJson(
    Map<String, dynamic> j,
  ) => ServiceRequestAttachmentModel(
    id: (j['id'] ?? '').toString(),
    originalFileName: (j['originalFileName'] ?? 'attachment').toString(),
    contentType: (j['contentType'] ?? 'application/octet-stream').toString(),
    fileSizeBytes: (j['fileSizeBytes'] as num?)?.toInt() ?? 0,
    downloadUrl: j['downloadUrl']?.toString(),
    uploadedAt:
        DateTime.tryParse((j['uploadedAt'] ?? '').toString()) ?? DateTime.now(),
  );
}

class ServiceRequestModel extends ServiceRequestEntity {
  const ServiceRequestModel({
    required super.id,
    required super.appointmentId,
    super.consultationId,
    super.admissionId,
    required super.category,
    required super.serviceCode,
    required super.serviceName,
    required super.description,
    required super.unitPrice,
    required super.quantity,
    required super.totalAmount,
    required super.currencyCode,
    required super.status,
    required super.paymentStatus,
    required super.patientCopayAmount,
    required super.insuranceCoveredAmount,
    required super.requestedByName,
    required super.requestedAt,
    super.notes,
    super.resultSummary,
    super.resultFileUrl,
    super.resultNotes,
    super.attachments,
    super.executedAt,
    super.completedAt,
  });

  factory ServiceRequestModel.fromJson(Map<String, dynamic> j) {
    final attachmentsRaw = j['attachments'];
    final attachments = (attachmentsRaw is List)
        ? attachmentsRaw
              .whereType<Map<String, dynamic>>()
              .map(ServiceRequestAttachmentModel.fromJson)
              .toList()
        : const <ServiceRequestAttachmentModel>[];

    return ServiceRequestModel(
      id: (j['id'] ?? '').toString(),
      appointmentId: (j['appointmentId'] ?? '').toString(),
      consultationId: j['consultationId']?.toString(),
      admissionId: j['admissionId']?.toString(),
      category: (j['category'] ?? 'Unknown').toString(),
      serviceCode: (j['serviceCode'] ?? '').toString(),
      serviceName: (j['serviceName'] ?? '').toString(),
      description: (j['description'] ?? '').toString(),
      unitPrice: (j['unitPrice'] as num?) ?? 0,
      quantity: (j['quantity'] as num?)?.toInt() ?? 1,
      totalAmount: (j['totalAmount'] as num?) ?? 0,
      currencyCode: (j['currencyCode'] ?? 'KES').toString(),
      status: (j['status'] ?? 'Requested').toString(),
      paymentStatus: (j['paymentStatus'] ?? 'PendingAssessment').toString(),
      patientCopayAmount: (j['patientCopayAmount'] as num?) ?? 0,
      insuranceCoveredAmount: (j['insuranceCoveredAmount'] as num?) ?? 0,
      requestedByName: (j['requestedByName'] ?? '').toString(),
      requestedAt:
          DateTime.tryParse((j['requestedAt'] ?? '').toString()) ??
          DateTime.now(),
      notes: j['notes']?.toString(),
      resultSummary: j['resultSummary']?.toString(),
      resultFileUrl: j['resultFileUrl']?.toString(),
      resultNotes: j['resultNotes']?.toString(),
      attachments: attachments,
      executedAt: j['executedAt'] != null
          ? DateTime.tryParse(j['executedAt'].toString())
          : null,
      completedAt: j['completedAt'] != null
          ? DateTime.tryParse(j['completedAt'].toString())
          : null,
    );
  }
}
