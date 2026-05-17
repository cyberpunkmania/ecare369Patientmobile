import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/theme_config.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../routes/app_router.dart';
import '../bloc/bills_cubit.dart';

class BillsListPage extends StatelessWidget {
  const BillsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BillsCubit>(
      create: (_) => sl<BillsCubit>()..loadList(),
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
        title: const Text('Bills'),
        backgroundColor: AppColors.mint,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<BillsCubit>().loadList(),
          ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<BillsCubit, BillsState>(
          builder: (context, state) {
            if (state.loading && state.bills.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            if (state.errorMessage != null && state.bills.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        state.errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        onPressed: () => context.read<BillsCubit>().loadList(),
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (state.bills.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 56,
                        color: AppColors.textHint,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No bills yet',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Bills issued at the front desk will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return LayoutBuilder(
              builder: (context, c) {
                final width = c.maxWidth;
                final isTablet = width >= 600;
                final pad = isTablet ? 32.0 : (width < 360 ? 16.0 : 20.0);
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => context.read<BillsCubit>().loadList(),
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(pad, 8, pad, 40),
                    itemCount: state.bills.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final b = state.bills[i];
                      return Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: isTablet ? 720 : double.infinity,
                          ),
                          child: _BillCard(
                            bill: b,
                            onTap: () => Navigator.of(
                              context,
                            ).pushNamed(Routes.billDetail, arguments: b.id),
                          ),
                        ),
                      );
                    },
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

class _BillCard extends StatelessWidget {
  final dynamic bill;
  final VoidCallback onTap;
  const _BillCard({required this.bill, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isPaid = bill.status.toString().toLowerCase() == 'paid';
    final balance = bill.balanceDue as num;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.mintDeep.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bill.billNumber ?? 'Bill #${bill.id.substring(0, 6)}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                    ),
                  ),
                  Text(
                    DateFormat('d MMM yyyy').format(bill.issuedAt),
                    style: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${bill.currency} ${(bill.total as num).toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isPaid
                        ? AppColors.mint
                        : AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isPaid
                        ? 'Paid'
                        : 'Due ${bill.currency} ${balance.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: isPaid ? AppColors.primary : AppColors.warning,
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
