import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/theme_config.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/service_request_entity.dart';
import '../bloc/orders_cubit.dart';

class OrderDetailPage extends StatelessWidget {
  final String orderId;
  const OrderDetailPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrdersCubit>(
      create: (_) => sl<OrdersCubit>()..loadDetail(orderId),
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
        title: const Text('Order Detail'),
        backgroundColor: AppColors.mint,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: BlocBuilder<OrdersCubit, OrdersState>(
          builder: (context, state) {
            if (state.status == OrdersStatus.loading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            if (state.status == OrdersStatus.error) {
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
                        state.errorMessage ?? 'Unable to load order',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        onPressed: () {
                          final id =
                              (ModalRoute.of(context)?.settings.arguments
                                  as String?) ??
                              '';
                          if (id.isNotEmpty) {
                            context.read<OrdersCubit>().loadDetail(id);
                          }
                        },
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              );
            }
            final order = state.selectedOrder;
            if (order == null) {
              return const SizedBox.shrink();
            }
            return _OrderDetailBody(order: order);
          },
        ),
      ),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _OrderDetailBody extends StatelessWidget {
  final ServiceRequestEntity order;
  const _OrderDetailBody({required this.order});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    return LayoutBuilder(
      builder: (context, c) {
        final isTablet = c.maxWidth >= 600;
        final pad = isTablet ? 32.0 : (c.maxWidth < 360 ? 16.0 : 20.0);
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(pad, 8, pad, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isTablet ? 720 : double.infinity,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Hero card ──────────────────────────────────────────
                  _HeroCard(order: order),
                  const SizedBox(height: 14),

                  // ── Status timeline ────────────────────────────────────
                  _SectionCard(
                    title: 'Progress',
                    icon: Icons.timeline_rounded,
                    child: _StatusTimeline(order: order),
                  ),
                  const SizedBox(height: 14),

                  // ── Cost breakdown ─────────────────────────────────────
                  _SectionCard(
                    title: 'Cost Breakdown',
                    icon: Icons.payments_outlined,
                    child: _CostBreakdown(order: order, fmt: fmt),
                  ),

                  // ── Result summary ─────────────────────────────────────
                  if (order.resultSummary != null ||
                      order.resultNotes != null) ...[
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: 'Result Summary',
                      icon: Icons.science_outlined,
                      child: _ResultSummary(order: order),
                    ),
                  ],

                  // ── Attachments ────────────────────────────────────────
                  if (order.attachments.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: 'Attachments',
                      icon: Icons.attach_file_rounded,
                      child: _AttachmentsList(attachments: order.attachments),
                    ),
                  ],

                  // ── Notes ──────────────────────────────────────────────
                  if (order.notes != null) ...[
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: 'Notes',
                      icon: Icons.note_outlined,
                      child: Text(
                        order.notes!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Hero card ────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final ServiceRequestEntity order;
  const _HeroCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('d MMM yyyy, h:mm a');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _categoryIcon(order.category),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.category,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      order.serviceName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              _WhiteStatusChip(status: order.status),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _HeroDetailItem(label: 'Code', value: order.serviceCode),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _HeroDetailItem(
                  label: 'Requested by',
                  value: order.requestedByName,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _HeroDetailItem(
            label: 'Requested on',
            value: dateFmt.format(order.requestedAt.toLocal()),
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'Lab':
        return Icons.biotech_outlined;
      case 'Radiology':
        return Icons.document_scanner_outlined;
      case 'Pharmacy':
        return Icons.medication_outlined;
      case 'Procedure':
        return Icons.medical_services_outlined;
      case 'Accommodation':
        return Icons.bed_outlined;
      default:
        return Icons.assignment_outlined;
    }
  }
}

class _HeroDetailItem extends StatelessWidget {
  final String label;
  final String value;
  const _HeroDetailItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _WhiteStatusChip extends StatelessWidget {
  final String status;
  const _WhiteStatusChip({required this.status});

  String _label(String s) {
    if (s == 'InProgress') return 'In Progress';
    return s;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white38),
      ),
      child: Text(
        _label(status),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Section card ─────────────────────────────────────────────────────────────

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
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.mintDeep.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ─── Status timeline ──────────────────────────────────────────────────────────

class _StatusTimeline extends StatelessWidget {
  final ServiceRequestEntity order;
  const _StatusTimeline({required this.order});

  static const _steps = [
    ('Requested', 'Requested'),
    ('Approved', 'Approved'),
    ('InProgress', 'In Progress'),
    ('Completed', 'Completed'),
  ];

  @override
  Widget build(BuildContext context) {
    if (order.isCancelled) {
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cancel_outlined,
              color: AppColors.error,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'This order was cancelled',
            style: TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    final currentIndex = _currentStepIndex(order.status);

    return Column(
      children: List.generate(_steps.length, (i) {
        final (key, label) = _steps[i];
        final isActive = i <= currentIndex;
        final isCurrent = i == currentIndex;
        final isLast = i == _steps.length - 1;
        final ts = _timestampFor(key);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dot + line
            Column(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary
                        : AppColors.mintDeep.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCurrent ? AppColors.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: isActive
                      ? const Icon(Icons.check, size: 11, color: Colors.white)
                      : null,
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 32,
                    color: isActive && i < currentIndex
                        ? AppColors.primary.withValues(alpha: 0.4)
                        : AppColors.mintDeep.withValues(alpha: 0.4),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: isActive
                            ? AppColors.textPrimary
                            : AppColors.textHint,
                        fontWeight: isCurrent
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 13.5,
                      ),
                    ),
                    if (ts != null)
                      Text(
                        DateFormat('d MMM yyyy, h:mm a').format(ts.toLocal()),
                        style: const TextStyle(
                          color: AppColors.textHint,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  int _currentStepIndex(String status) {
    switch (status) {
      case 'Approved':
        return 1;
      case 'InProgress':
        return 2;
      case 'Completed':
        return 3;
      default:
        return 0; // Requested
    }
  }

  DateTime? _timestampFor(String step) {
    switch (step) {
      case 'Requested':
        return order.requestedAt;
      case 'InProgress':
        return order.executedAt;
      case 'Completed':
        return order.completedAt;
      default:
        return null;
    }
  }
}

// ─── Cost breakdown ───────────────────────────────────────────────────────────

class _CostBreakdown extends StatelessWidget {
  final ServiceRequestEntity order;
  final NumberFormat fmt;
  const _CostBreakdown({required this.order, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CostRow(
          label: 'Service',
          value: '${order.currencyCode} ${fmt.format(order.unitPrice)}',
          muted: true,
        ),
        if (order.quantity > 1)
          _CostRow(
            label: 'Quantity',
            value: '× ${order.quantity}',
            muted: true,
          ),
        const Divider(height: 16),
        _CostRow(
          label: 'Total',
          value: '${order.currencyCode} ${fmt.format(order.totalAmount)}',
          bold: true,
        ),
        if (order.insuranceCoveredAmount > 0)
          _CostRow(
            label: 'Insurance covered',
            value:
                '- ${order.currencyCode} ${fmt.format(order.insuranceCoveredAmount)}',
            color: const Color(0xFF27AE60),
          ),
        if (order.patientCopayAmount > 0) ...[
          const Divider(height: 16),
          _CostRow(
            label: 'Your contribution',
            value:
                '${order.currencyCode} ${fmt.format(order.patientCopayAmount)}',
            bold: true,
            color: AppColors.primary,
          ),
        ],
        const SizedBox(height: 8),
        _PaymentStatusBadge(status: order.paymentStatus),
      ],
    );
  }
}

class _CostRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final bool muted;
  final Color? color;

  const _CostRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.muted = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textColor =
        color ?? (muted ? AppColors.textSecondary : AppColors.textPrimary);
    final style = TextStyle(
      color: textColor,
      fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
      fontSize: bold ? 15 : 13.5,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _PaymentStatusBadge extends StatelessWidget {
  final String status;
  const _PaymentStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, bg, label) = _meta(status);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }

  (Color, Color, String) _meta(String s) {
    switch (s) {
      case 'FullyCovered':
        return (
          const Color(0xFF27AE60),
          const Color(0xFFE8F8F0),
          'Fully covered by insurance',
        );
      case 'Waived':
        return (
          AppColors.primary,
          AppColors.primary.withValues(alpha: 0.1),
          'Waived',
        );
      case 'Approved':
        return (
          AppColors.primary,
          AppColors.primary.withValues(alpha: 0.1),
          'Payment approved',
        );
      case 'CopayRequired':
        return (
          const Color(0xFFE67E22),
          const Color(0xFFFEF3E7),
          'Co-pay required from you',
        );
      default:
        return (
          AppColors.textHint,
          const Color(0xFFF0F0F4),
          'Pending assessment',
        );
    }
  }
}

// ─── Result summary ───────────────────────────────────────────────────────────

class _ResultSummary extends StatelessWidget {
  final ServiceRequestEntity order;
  const _ResultSummary({required this.order});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (order.resultSummary != null) ...[
          const Text(
            'Summary',
            style: TextStyle(
              color: AppColors.textHint,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            order.resultSummary!,
            style: const TextStyle(color: AppColors.textPrimary, height: 1.5),
          ),
        ],
        if (order.resultNotes != null) ...[
          const SizedBox(height: 10),
          const Text(
            'Clinician notes',
            style: TextStyle(
              color: AppColors.textHint,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            order.resultNotes!,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        if (order.resultFileUrl != null) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('View full report'),
            onPressed: () async {
              final uri = Uri.tryParse(order.resultFileUrl!);
              if (uri != null && await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ],
    );
  }
}

// ─── Attachments list ─────────────────────────────────────────────────────────

class _AttachmentsList extends StatelessWidget {
  final List<ServiceRequestAttachmentEntity> attachments;
  const _AttachmentsList({required this.attachments});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: attachments.map((a) => _AttachmentTile(attachment: a)).toList(),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  final ServiceRequestAttachmentEntity attachment;
  const _AttachmentTile({required this.attachment});

  String _fileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final hasLink = attachment.downloadUrl != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: hasLink
            ? () async {
                final uri = Uri.tryParse(attachment.downloadUrl!);
                if (uri != null && await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              }
            : null,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.mint,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.mintDeep.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Icon(
                attachment.isPdf
                    ? Icons.picture_as_pdf_outlined
                    : attachment.isImage
                    ? Icons.image_outlined
                    : Icons.insert_drive_file_outlined,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attachment.originalFileName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _fileSize(attachment.fileSizeBytes),
                      style: const TextStyle(
                        color: AppColors.textHint,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasLink)
                const Icon(
                  Icons.download_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
