import 'package:equatable/equatable.dart';

class DispensationEntity extends Equatable {
  final String id;
  final String? prescriptionId;
  final String medicationName;
  final num quantity;
  final String? unit;
  final String? instructions;
  final DateTime dispensedAt;
  final String? pharmacistName;
  final String status;

  const DispensationEntity({
    required this.id,
    required this.medicationName,
    required this.quantity,
    required this.dispensedAt,
    required this.status,
    this.prescriptionId,
    this.unit,
    this.instructions,
    this.pharmacistName,
  });

  @override
  List<Object?> get props => [
    id,
    prescriptionId,
    medicationName,
    quantity,
    unit,
    instructions,
    dispensedAt,
    pharmacistName,
    status,
  ];
}
