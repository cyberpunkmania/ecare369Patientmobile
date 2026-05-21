import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/theme_config.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../routes/app_router.dart';
import '../../../appointments/data/models/my_appointment_dto.dart';
import '../../../appointments/presentation/bloc/appointment_bloc.dart';
import '../../../appointments/presentation/bloc/appointment_event.dart';
import '../../../appointments/presentation/bloc/appointment_state.dart';
import '../../domain/entities/service_request_entity.dart';
import '../bloc/orders_cubit.dart';

class OrdersListPage extends StatelessWidget {
  final String appointmentId;
  const OrdersListPage({super.key, required this.appointmentId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrdersCubit>(
      create: (_) => appointmentId.isNotEmpty
          ? (sl<OrdersCubit>()..loadByAppointment(appointmentId))
          : sl<OrdersCubit>(),
      child: _View(appointmentId: appointmentId),
    );
  }
}

class _View extends StatelessWidget {
  final String appointmentId;
  const _View({required this.appointmentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mint,
      appBar: AppBar(
        title: const Text('Orders & Lab Results'),
        backgroundColor: AppColors.mint,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          if (appointmentId.isNotEmpty)
            BlocBuilder<OrdersCubit, OrdersState>(
              builder: (context, state) => IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: state.status == OrdersStatus.loading
                    ? null
                    : () => context.read<OrdersCubit>().loadByAppointment(
                        appointmentId,
                      ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: appointmentId.isEmpty
            ? const _AppointmentPickerView()
            : BlocBuilder<OrdersCubit, OrdersState>(
                builder: (context, state) =>
                    _OrdersBody(appointmentId: appointmentId, state: state),
              ),
      ),
    );
  }
}

// ─── Body widget ─────────────────────────────────────────────────────────────

class _OrdersBody extends StatelessWidget {
  final String appointmentId;
  final OrdersState state;
  const _OrdersBody({required this.appointmentId, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.status == OrdersStatus.loading && state.orders.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (state.status == OrdersStatus.error && state.orders.isEmpty) {
      return _ErrorView(
        message: state.errorMessage ?? 'Unable to load orders',
        onRetry: () =>
            context.read<OrdersCubit>().loadByAppointment(appointmentId),
      );
    }
    if (state.orders.isEmpty) {
      return const _EmptyView();
    }
    return LayoutBuilder(
      builder: (context, c) {
        final isTablet = c.maxWidth >= 600;
        final pad = isTablet ? 32.0 : (c.maxWidth < 360 ? 16.0 : 20.0);

        final grouped = state.grouped;
        final ordered = _categoryOrder(grouped.keys.toList());
        final items = <_ListItem>[];
        for (final cat in ordered) {
          items.add(_ListItem.header(cat));
          for (final o in grouped[cat] ?? []) {
            items.add(_ListItem.order(o));
          }
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () =>
              context.read<OrdersCubit>().loadByAppointment(appointmentId),
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(pad, 8, pad, 40),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i];
              if (item.isHeader) {
                return _CategoryHeader(label: item.header!);
              }
              final order = item.order!;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isTablet ? 720 : double.infinity,
                    ),
                    child: _OrderCard(
                      order: order,
                      onTap: () => Navigator.of(
                        context,
                      ).pushNamed(Routes.orderDetail, arguments: order.id),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  List<String> _categoryOrder(List<String> cats) {
    const priority = [
      'Lab',
      'Radiology',
      'Pharmacy',
      'Procedure',
      'Accommodation',
    ];
    final sorted = [...priority.where(cats.contains)];
    for (final c in cats) {
      if (!sorted.contains(c)) sorted.add(c);
    }
    return sorted;
  }
}

// ─── Appointment picker (shown when no appointmentId given) ──────────────────

class _AppointmentPickerView extends StatelessWidget {
  const _AppointmentPickerView();

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AppointmentBloc>(
      create: (_) => sl<AppointmentBloc>()..add(AppointmentsLoaded()),
      child: const _AppointmentPickerBody(),
    );
  }
}

class _AppointmentPickerBody extends StatelessWidget {
  const _AppointmentPickerBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppointmentBloc, AppointmentState>(
      builder: (context, state) {
        if (state is AppointmentInitial || state is AppointmentLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        if (state is AppointmentError) {
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
                    state.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    onPressed: () => context.read<AppointmentBloc>().add(
                      AppointmentsLoaded(),
                    ),
                    child: const Text('Try again'),
                  ),
                ],
              ),
            ),
          );
        }
        if (state is AppointmentListLoaded) {
          if (state.appointments.isEmpty) {
            return const Center(
              child: Text(
                'No appointments found',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Select an appointment to view its orders',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  itemCount: state.appointments.length,
                  itemBuilder: (context, i) => _AppointmentPickerCard(
                    appointment: state.appointments[i],
                  ),
                ),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _AppointmentPickerCard extends StatelessWidget {
  final MyAppointmentDto appointment;
  const _AppointmentPickerCard({required this.appointment});

  Color _statusColor(AppointmentStatus s) {
    switch (s) {
      case AppointmentStatus.Completed:
        return const Color(0xFF27AE60);
      case AppointmentStatus.Cancelled:
      case AppointmentStatus.NoShow:
        return AppColors.error;
      case AppointmentStatus.InConsultation:
      case AppointmentStatus.CheckedIn:
        return AppColors.primary;
      default:
        return const Color(0xFFE67E22);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('EEE, d MMM yyyy');
    final date = dateFmt.format(
      DateTime.tryParse(appointment.appointmentDate) ?? DateTime.now(),
    );
    final statusColor = _statusColor(appointment.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(
          context,
        ).pushNamed(Routes.ordersList, arguments: appointment.id),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.mintDeep.withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.event_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.doctorName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (appointment.doctorSpecialization.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        appointment.doctorSpecialization,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      date,
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      appointment.status.name,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textHint,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── List item model ──────────────────────────────────────────────────────────

class _ListItem {
  final String? header;
  final ServiceRequestEntity? order;

  const _ListItem.header(String h) : header = h, order = null;
  const _ListItem.order(ServiceRequestEntity o) : header = null, order = o;

  bool get isHeader => header != null;
}

// ─── Category header ─────────────────────────────────────────────────────────

class _CategoryHeader extends StatelessWidget {
  final String label;
  const _CategoryHeader({required this.label});

  IconData get _icon {
    switch (label) {
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
        return Icons.category_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Row(
        children: [
          Icon(_icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Order card ──────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final ServiceRequestEntity order;
  final VoidCallback onTap;
  const _OrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    final dateFmt = DateFormat('d MMM yyyy, h:mm a');

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon badge
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _categoryColor(order.category).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _categoryIcon(order.category),
                color: _categoryColor(order.category),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          order.serviceName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusChip(status: order.status),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    order.serviceCode,
                    style: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 11.5,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Cost row
                  Row(
                    children: [
                      Text(
                        '${order.currencyCode} ${fmt.format(order.totalAmount)}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _PaymentChip(status: order.paymentStatus),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Date + result indicator
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 12,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          dateFmt.format(order.requestedAt.toLocal()),
                          style: const TextStyle(
                            color: AppColors.textHint,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                      if (order.hasResults)
                        const Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 13,
                              color: Colors.green,
                            ),
                            SizedBox(width: 3),
                            Text(
                              'Results ready',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textHint,
              size: 20,
            ),
          ],
        ),
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

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'Lab':
        return const Color(0xFF5B67CA);
      case 'Radiology':
        return const Color(0xFFE67E22);
      case 'Pharmacy':
        return AppColors.primary;
      case 'Procedure':
        return const Color(0xFFE74C3C);
      case 'Accommodation':
        return const Color(0xFF27AE60);
      default:
        return AppColors.textSecondary;
    }
  }
}

// ─── Status chip ─────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, bg) = _palette(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _label(status),
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _label(String s) {
    switch (s) {
      case 'InProgress':
        return 'In Progress';
      case 'PendingAssessment':
        return 'Pending';
      default:
        return s;
    }
  }

  (Color, Color) _palette(String s) {
    switch (s) {
      case 'Completed':
        return (const Color(0xFF27AE60), const Color(0xFFE8F8F0));
      case 'Approved':
        return (AppColors.primary, AppColors.primary.withValues(alpha: 0.1));
      case 'InProgress':
        return (const Color(0xFFE67E22), const Color(0xFFFEF3E7));
      case 'Cancelled':
        return (AppColors.error, AppColors.error.withValues(alpha: 0.1));
      default: // Requested
        return (AppColors.textSecondary, const Color(0xFFF0F0F4));
    }
  }
}

// ─── Payment chip ────────────────────────────────────────────────────────────

class _PaymentChip extends StatelessWidget {
  final String status;
  const _PaymentChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, bg, label) = _meta(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  (Color, Color, String) _meta(String s) {
    switch (s) {
      case 'FullyCovered':
        return (const Color(0xFF27AE60), const Color(0xFFE8F8F0), 'Covered');
      case 'Approved':
      case 'Waived':
        return (
          AppColors.primary,
          AppColors.primary.withValues(alpha: 0.1),
          s == 'Waived' ? 'Waived' : 'Approved',
        );
      case 'CopayRequired':
        return (const Color(0xFFE67E22), const Color(0xFFFEF3E7), 'Copay');
      default:
        return (AppColors.textHint, const Color(0xFFF0F0F4), 'Pending');
    }
  }
}

// ─── Empty & error states ─────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.biotech_outlined, size: 56, color: AppColors.textHint),
            SizedBox(height: 12),
            Text(
              'No orders yet',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Lab, radiology, and procedure orders for this\nappointment will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
