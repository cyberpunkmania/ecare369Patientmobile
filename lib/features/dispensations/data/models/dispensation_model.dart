import '../../domain/entities/dispensation_entity.dart';

class DispensationModel extends DispensationEntity {
  const DispensationModel({
    required super.id,
    required super.medicationName,
    required super.quantity,
    required super.dispensedAt,
    required super.status,
    super.prescriptionId,
    super.unit,
    super.instructions,
    super.pharmacistName,
  });

  factory DispensationModel.fromJson(Map<String, dynamic> j) {
    return DispensationModel(
      id: (j['_id'] ?? j['id'] ?? '').toString(),
      prescriptionId: j['prescriptionId']?.toString(),
      medicationName:
          (j['medicationName'] ??
                  j['drugName'] ??
                  j['itemName'] ??
                  j['name'] ??
                  'Medication')
              .toString(),
      quantity: (j['quantity'] as num?) ?? 0,
      unit: j['unit']?.toString(),
      instructions: (j['instructions'] ?? j['dosageInstructions'])?.toString(),
      pharmacistName: (j['pharmacistName'] ?? j['dispensedBy'])?.toString(),
      dispensedAt:
          DateTime.tryParse(
            (j['dispensedAt'] ?? j['createdAt'] ?? '').toString(),
          ) ??
          DateTime.now(),
      status: (j['status'] ?? 'dispensed').toString(),
    );
  }
}
