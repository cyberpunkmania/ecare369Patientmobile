import '../../domain/entities/dispensation_entity.dart';

class DispensationLineModel extends DispensationLineEntity {
  const DispensationLineModel({
    required super.id,
    required super.drugName,
    required super.quantityDispensed,
    required super.unitSellingPrice,
    required super.totalSellingPrice,
  });

  factory DispensationLineModel.fromJson(Map<String, dynamic> j) {
    return DispensationLineModel(
      id: (j['id'] ?? j['_id'] ?? '').toString(),
      drugName:
          (j['drugName'] ?? j['itemName'] ?? j['name'] ?? 'Medication')
              .toString(),
      quantityDispensed:
          (j['quantityDispensed'] as num?) ?? (j['quantity'] as num?) ?? 0,
      unitSellingPrice: (j['unitSellingPrice'] as num?) ?? 0,
      totalSellingPrice: (j['totalSellingPrice'] as num?) ?? 0,
    );
  }
}

class DispensationModel extends DispensationEntity {
  const DispensationModel({
    required super.id,
    required super.medicationName,
    required super.quantity,
    required super.dispensedAt,
    required super.status,
    required super.lines,
    super.prescriptionId,
    super.dispensationNumber,
    super.unit,
    super.instructions,
    super.pharmacistName,
    super.totalRevenue,
  });

  factory DispensationModel.fromJson(Map<String, dynamic> j) {
    final rawLines =
        (j['lines'] as List?)?.whereType<Map<String, dynamic>>().toList() ?? [];
    final lines = rawLines.map(DispensationLineModel.fromJson).toList();

    // Build medication name from line items
    final String medicationName;
    if (lines.isEmpty) {
      medicationName =
          (j['medicationName'] ??
                  j['drugName'] ??
                  j['itemName'] ??
                  j['name'] ??
                  'Medication')
              .toString();
    } else if (lines.length == 1) {
      medicationName = lines.first.drugName;
    } else {
      medicationName = '${lines.first.drugName} +${lines.length - 1} more';
    }

    // Total quantity dispensed across all line items
    final totalQty =
        lines.isEmpty
            ? (j['quantity'] as num?) ?? 0
            : lines.fold<num>(0, (sum, l) => sum + l.quantityDispensed);

    return DispensationModel(
      id: (j['id'] ?? j['_id'] ?? '').toString(),
      dispensationNumber: j['dispensationNumber']?.toString(),
      prescriptionId: j['prescriptionId']?.toString(),
      medicationName: medicationName,
      quantity: totalQty,
      unit: j['unit']?.toString(),
      instructions: (j['instructions'] ?? j['dosageInstructions'])?.toString(),
      pharmacistName: (j['pharmacistName'] ?? j['dispensedBy'])?.toString(),
      dispensedAt:
          DateTime.tryParse(
            (j['dispensedAt'] ?? j['createdAt'] ?? '').toString(),
          ) ??
          DateTime.now(),
      status: (j['status'] ?? 'dispensed').toString(),
      totalRevenue: j['totalRevenue'] as num?,
      lines: lines,
    );
  }
}
