import 'package:equatable/equatable.dart';

class BillEntity extends Equatable {
  final String id;
  final String? billNumber;
  final String? patientName;
  final DateTime issuedAt;
  final num subtotal;
  final num tax;
  final num discount;
  final num total;
  final num amountPaid;
  final num balanceDue;
  final String status;
  final String currency;
  final List<BillLineItemEntity> items;
  final List<PaymentEntity> payments;

  const BillEntity({
    required this.id,
    required this.issuedAt,
    required this.subtotal,
    required this.tax,
    required this.discount,
    required this.total,
    required this.amountPaid,
    required this.balanceDue,
    required this.status,
    this.currency = 'USD',
    this.items = const [],
    this.payments = const [],
    this.billNumber,
    this.patientName,
  });

  @override
  List<Object?> get props => [
    id,
    billNumber,
    patientName,
    issuedAt,
    subtotal,
    tax,
    discount,
    total,
    amountPaid,
    balanceDue,
    status,
    currency,
    items,
    payments,
  ];
}

class BillLineItemEntity extends Equatable {
  final String description;
  final num quantity;
  final num unitPrice;
  final num lineTotal;

  const BillLineItemEntity({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  @override
  List<Object?> get props => [description, quantity, unitPrice, lineTotal];
}

class PaymentEntity extends Equatable {
  final String? id;
  final num amount;
  final String? method;
  final DateTime paidAt;
  final String? reference;

  const PaymentEntity({
    required this.amount,
    required this.paidAt,
    this.id,
    this.method,
    this.reference,
  });

  @override
  List<Object?> get props => [id, amount, method, paidAt, reference];
}
