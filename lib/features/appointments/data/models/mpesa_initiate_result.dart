import 'package:equatable/equatable.dart';

/// Result returned by `POST /api/third-party-client-integrations/payments/initiate`.
class MpesaInitiateResult extends Equatable {
  final String paymentId;
  final String status;
  final String? customerMessage;
  final String phoneNumber;
  final double amount;
  final String? currency;
  final DateTime? expiresAt;

  const MpesaInitiateResult({
    required this.paymentId,
    required this.status,
    required this.phoneNumber,
    required this.amount,
    this.currency,
    this.customerMessage,
    this.expiresAt,
  });

  factory MpesaInitiateResult.fromJson(Map<String, dynamic> json) {
    final amt = json['amount'];
    return MpesaInitiateResult(
      paymentId: (json['paymentId'] ?? json['id'] ?? '').toString(),
      status: (json['status'] ?? 'Pending').toString(),
      phoneNumber: (json['phoneNumber'] ?? '').toString(),
      amount: amt is num ? amt.toDouble() : double.tryParse('$amt') ?? 0,
      currency: json['currency'] as String?,
      customerMessage: json['customerMessage'] as String?,
      expiresAt: json['expiresAt'] is String
          ? DateTime.tryParse(json['expiresAt'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
    paymentId,
    status,
    phoneNumber,
    amount,
    currency,
    customerMessage,
    expiresAt,
  ];
}
