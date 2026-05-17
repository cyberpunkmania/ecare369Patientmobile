import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/theme_config.dart';
import '../../../../routes/app_router.dart';
import '../../data/models/my_appointment_dto.dart';
import '../bloc/appointment_bloc.dart';
import '../bloc/appointment_event.dart';
import '../bloc/appointment_state.dart';

/// Detail page â€“ receives a [MyAppointmentDto].
class AppointmentDetailPage extends StatelessWidget {
  final MyAppointmentDto? appointment;
  final String? appointmentId;

  const AppointmentDetailPage({
    super.key,
    this.appointment,
    this.appointmentId,
  });

  String _formatTime(String? startTime, String? endTime) {
    if (startTime == null) return '';
    try {
      final start = DateFormat('HH:mm:ss').parse(startTime);
      final startStr = DateFormat('HH:mm').format(start);
      if (endTime == null) return startStr;
      final end = DateFormat('HH:mm:ss').parse(endTime);
      return '$startStr - ${DateFormat('HH:mm').format(end)}';
    } catch (_) {
      return startTime;
    }
  }

  Future<void> _confirmCancel(BuildContext context, String appointmentId) async {
    final reasonController = TextEditingController();
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Icon + title
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.cancel_outlined, color: AppColors.error, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Cancel Appointment',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              const Text(
                'Are you sure you want to cancel this appointment? This action cannot be undone.',
                style: TextStyle(color: Colors.black54, height: 1.4),
              ),
              const SizedBox(height: 16),

              // Optional reason field
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason (optional)',
                  hintText: 'e.g. Schedule conflict',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(sheetCtx).pop(false),
                      child: const Text('Keep'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.of(sheetCtx).pop(true),
                      child: const Text('Yes, Cancel'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      final reason = reasonController.text.trim().isEmpty
          ? 'Patient requested cancellation'
          : reasonController.text.trim();
      context.read<AppointmentBloc>().add(
        AppointmentCancelled(id: appointmentId, reason: reason),
      );
    }
    reasonController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (appointment == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Appointment')),
        body: const Center(child: Text('Appointment not found.')),
      );
    }

    final apt = appointment!;
    String dateStr;
    try {
      final date = DateTime.parse(apt.appointmentDate);
      dateStr = DateFormat('EEEE, MMMM d, yyyy').format(date);
    } catch (_) {
      dateStr = apt.appointmentDate;
    }
    final statusName = apt.status.name;

    return BlocConsumer<AppointmentBloc, AppointmentState>(
      listener: (context, state) {
        if (state is AppointmentCancelledSuccess) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Appointment cancelled successfully.')),
          );
        } else if (state is AppointmentError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AppointmentLoading;

        return Scaffold(
          appBar: AppBar(title: const Text('Appointment Details')),
          body: Stack(
            children: [
              LayoutBuilder(
                builder: (context, c) {
                  final width = c.maxWidth;
                  final isTablet = width >= 600;
                  final pad = isTablet ? 32.0 : (width < 360 ? 12.0 : 16.0);
                  return SingleChildScrollView(
                    padding: EdgeInsets.all(pad),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isTablet ? 720 : double.infinity,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Doctor card
                            Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primaryLight,
                                  child: Text(
                                    apt.doctorName.isNotEmpty
                                        ? apt.doctorName[0]
                                        : 'D',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  apt.doctorName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  apt.doctorSpecialization.isNotEmpty
                                      ? apt.doctorSpecialization
                                      : 'General',
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            _InfoRow(
                              icon: Icons.calendar_today,
                              label: 'Date',
                              value: dateStr,
                            ),
                            _InfoRow(
                              icon: Icons.access_time,
                              label: 'Time',
                              value: _formatTime(apt.startTime, apt.endTime),
                            ),
                            _InfoRow(
                              icon: Icons.category,
                              label: 'Type',
                              value: apt.appointmentTypeLabel,
                            ),
                            _InfoRow(
                              icon: Icons.info_outline,
                              label: 'Status',
                              value: statusName.toUpperCase(),
                              valueColor: _statusColor(statusName),
                            ),
                            if (apt.reasonForVisit != null &&
                                apt.reasonForVisit!.isNotEmpty)
                              _InfoRow(
                                icon: Icons.note,
                                label: 'Reason',
                                value: apt.reasonForVisit!,
                              ),
                            _InfoRow(
                              icon: Icons.payment,
                              label: 'Fee',
                              value:
                                  '${apt.currency} ${apt.consultationFee.toStringAsFixed(2)}',
                            ),
                            _InfoRow(
                              icon: Icons.receipt,
                              label: 'Payment',
                              value: apt.paymentStatus.name,
                            ),

                            const SizedBox(height: 24),

                            if (apt.status == AppointmentStatus.Scheduled) ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: isLoading
                                          ? null
                                          : () => _confirmCancel(context, apt.id),
                                      icon: const Icon(
                                        Icons.cancel,
                                        color: AppColors.error,
                                      ),
                                      label: const Text(
                                        'Cancel',
                                        style:
                                            TextStyle(color: AppColors.error),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: isLoading
                                          ? null
                                          : () => Navigator.of(context)
                                              .pushNamed(Routes.bookAppointment),
                                      icon: const Icon(Icons.schedule),
                                      label: const Text('Reschedule'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (isLoading)
                const ColoredBox(
                  color: Colors.black26,
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        );
      },
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return AppColors.info;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
