import 'package:equatable/equatable.dart';

class DispensationLineEntity extends Equatable {
  final String id;
  final String drugName;
  final num quantityDispensed;
  final num unitSellingPrice;
  final num totalSellingPrice;

  const DispensationLineEntity({
    required this.id,
    required this.drugName,
    required this.quantityDispensed,
    required this.unitSellingPrice,
    required this.totalSellingPrice,
  });

  @override
  List<Object?> get props => [
    id,
    drugName,
    quantityDispensed,
    unitSellingPrice,
    totalSellingPrice,
  ];
}

class DispensationEntity extends Equatable {
  final String id;
  final String? prescriptionId;
  final String? dispensationNumber;
  final String medicationName;
  final num quantity;
  final String? unit;
  final String? instructions;
  final DateTime dispensedAt;
  final String? pharmacistName;
  final String status;
  final num? totalRevenue;
  final List<DispensationLineEntity> lines;

  const DispensationEntity({
    required this.id,
    required this.medicationName,
    required this.quantity,
    required this.dispensedAt,
    required this.status,
    required this.lines,
    this.prescriptionId,
    this.dispensationNumber,
    this.unit,
    this.instructions,
    this.pharmacistName,
    this.totalRevenue,
  });

  @override
  List<Object?> get props => [
    id,
    prescriptionId,
    dispensationNumber,
    medicationName,
    quantity,
    unit,
    instructions,
    dispensedAt,
    pharmacistName,
    status,
    totalRevenue,
    lines,
  ];
}
