import '../../domain/entities/bill_entity.dart';

class BillLineItemModel extends BillLineItemEntity {
  const BillLineItemModel({
    required super.description,
    required super.quantity,
    required super.unitPrice,
    required super.lineTotal,
  });

  factory BillLineItemModel.fromJson(Map<String, dynamic> j) {
    final qty = (j['quantity'] as num?) ?? 1;
    final unit = (j['unitPrice'] as num?) ?? (j['price'] as num?) ?? 0;
    final line =
        (j['lineTotal'] as num?) ?? (j['amount'] as num?) ?? (qty * unit);
    return BillLineItemModel(
      description: (j['description'] ?? j['name'] ?? '').toString(),
      quantity: qty,
      unitPrice: unit,
      lineTotal: line,
    );
  }
}

class PaymentModel extends PaymentEntity {
  const PaymentModel({
    required super.amount,
    required super.paidAt,
    super.id,
    super.method,
    super.reference,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> j) => PaymentModel(
    id: (j['_id'] ?? j['id'])?.toString(),
    amount: (j['amount'] as num?) ?? 0,
    method: j['method']?.toString(),
    reference: j['reference']?.toString(),
    paidAt:
        DateTime.tryParse((j['paidAt'] ?? j['createdAt'] ?? '').toString()) ??
        DateTime.now(),
  );
}

class BillModel extends BillEntity {
  const BillModel({
    required super.id,
    required super.issuedAt,
    required super.subtotal,
    required super.tax,
    required super.discount,
    required super.total,
    required super.amountPaid,
    required super.balanceDue,
    required super.status,
    super.currency,
    super.items,
    super.payments,
    super.billNumber,
    super.patientName,
  });

  factory BillModel.fromJson(Map<String, dynamic> j) {
    final subtotal = (j['subtotal'] as num?) ?? 0;
    final tax = (j['tax'] as num?) ?? 0;
    final discount = (j['discount'] as num?) ?? 0;
    final total = (j['total'] as num?) ?? (subtotal + tax - discount);
    final paid = (j['amountPaid'] as num?) ?? (j['paid'] as num?) ?? 0;
    final balance = (j['balanceDue'] as num?) ?? (total - paid);
    final itemsRaw = j['items'] ?? j['lineItems'];
    final paymentsRaw = j['payments'];
    return BillModel(
      id: (j['_id'] ?? j['id'] ?? '').toString(),
      billNumber: (j['billNumber'] ?? j['invoiceNumber'])?.toString(),
      patientName: j['patientName']?.toString(),
      issuedAt:
          DateTime.tryParse(
            (j['issuedAt'] ?? j['createdAt'] ?? '').toString(),
          ) ??
          DateTime.now(),
      subtotal: subtotal,
      tax: tax,
      discount: discount,
      total: total,
      amountPaid: paid,
      balanceDue: balance,
      status: (j['status'] ?? 'unpaid').toString(),
      currency: (j['currency'] ?? 'USD').toString(),
      items: itemsRaw is List
          ? itemsRaw
                .whereType<Map<String, dynamic>>()
                .map(BillLineItemModel.fromJson)
                .toList()
          : const [],
      payments: paymentsRaw is List
          ? paymentsRaw
                .whereType<Map<String, dynamic>>()
                .map(PaymentModel.fromJson)
                .toList()
          : const [],
    );
  }
}
