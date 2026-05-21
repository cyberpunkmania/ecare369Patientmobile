import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../../../core/config/theme_config.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/top_notification.dart';
import '../../domain/entities/bill_entity.dart';
import '../bloc/bills_cubit.dart';

class BillDetailPage extends StatelessWidget {
  final String billId;
  const BillDetailPage({super.key, required this.billId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BillsCubit>(
      create: (_) => sl<BillsCubit>()..loadDetail(billId),
      child: const _View(),
    );
  }
}

class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mint,
      appBar: AppBar(
        title: const Text('Bill detail'),
        backgroundColor: AppColors.mint,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: BlocBuilder<BillsCubit, BillsState>(
          builder: (context, state) {
            if (state.loadingDetail && state.selected == null) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            final bill = state.selected;
            if (bill == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    state.errorMessage ?? 'Bill not found.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              );
            }
            return LayoutBuilder(
              builder: (context, c) {
                final width = c.maxWidth;
                final isTablet = width >= 600;
                final pad = isTablet ? 32.0 : (width < 360 ? 16.0 : 20.0);
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(pad, 8, pad, 40),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isTablet ? 720 : double.infinity,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Header(bill: bill),
                          const SizedBox(height: 14),
                          _ItemsCard(bill: bill),
                          const SizedBox(height: 14),
                          _TotalsCard(bill: bill),
                          const SizedBox(height: 14),
                          if (bill.payments.isNotEmpty)
                            _PaymentsCard(bill: bill),
                          if (bill.payments.isNotEmpty)
                            const SizedBox(height: 14),
                          _Actions(bill: bill),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final BillEntity bill;
  const _Header({required this.bill});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF0FB8A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            bill.billNumber ?? 'Bill #${bill.id.substring(0, 6)}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('d MMM yyyy').format(bill.issuedAt),
            style: const TextStyle(color: Colors.white70, fontSize: 12.5),
          ),
          const SizedBox(height: 14),
          Text(
            '${bill.currency} ${bill.total.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            bill.balanceDue > 0
                ? 'Balance due: ${bill.currency} ${bill.balanceDue.toStringAsFixed(2)}'
                : 'Fully paid',
            style: const TextStyle(color: Colors.white, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  final BillEntity bill;
  const _ItemsCard({required this.bill});
  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Line items',
      icon: Icons.list_alt_outlined,
      child: bill.items.isEmpty
          ? const Text(
              'No line items',
              style: TextStyle(color: AppColors.textHint),
            )
          : Column(
              children: bill.items
                  .map(
                    (it) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  it.description,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Qty ${it.quantity} \u00d7 ${bill.currency} ${it.unitPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: AppColors.textHint,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${bill.currency} ${it.lineTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  final BillEntity bill;
  const _TotalsCard({required this.bill});
  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Totals',
      icon: Icons.calculate_outlined,
      child: Column(
        children: [
          _row(context, 'Subtotal', bill.subtotal, bill.currency),
          _row(context, 'Tax', bill.tax, bill.currency),
          if (bill.discount != 0)
            _row(context, 'Discount', -bill.discount, bill.currency),
          const Divider(color: AppColors.mintDeep),
          _row(context, 'Total', bill.total, bill.currency, bold: true),
          _row(context, 'Paid', bill.amountPaid, bill.currency),
          _row(context, 'Balance', bill.balanceDue, bill.currency, bold: true),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    num value,
    String currency, {
    bool bold = false,
  }) {
    final style = TextStyle(
      color: AppColors.textPrimary,
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
      fontSize: 13.5,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text('$currency ${value.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }
}

class _PaymentsCard extends StatelessWidget {
  final BillEntity bill;
  const _PaymentsCard({required this.bill});
  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Payments',
      icon: Icons.payments_outlined,
      child: Column(
        children: bill.payments
            .map(
              (p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${p.method ?? 'Payment'} \u2022 ${DateFormat('d MMM yyyy').format(p.paidAt)}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    Text(
                      '${bill.currency} ${p.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  final BillEntity bill;
  const _Actions({required this.bill});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Download receipt (PDF)'),
            onPressed: () => _printReceipt(context, bill),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.mint,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primary),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Please pay at the reception desk. We will update the receipt automatically once your payment is recorded.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _printReceipt(BuildContext context, BillEntity bill) async {
    try {
      final cubit = context.read<BillsCubit>();
      final pdfBytes = await cubit.downloadBillPdf(bill.id);
      if (pdfBytes == null) {
        if (!context.mounted) return;
        TopNotification.show(
          context,
          'Could not download receipt.',
          type: NotificationType.error,
        );
        return;
      }
      await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
    } catch (e) {
      if (!context.mounted) return;
      TopNotification.show(
        context,
        'Could not download receipt: $e',
        type: NotificationType.error,
      );
    }
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.mintDeep.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Icon(icon, size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
