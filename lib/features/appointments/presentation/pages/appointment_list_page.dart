import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/theme_config.dart';
import '../../../../core/widgets/top_notification.dart';
import '../../data/models/my_appointment_dto.dart';
import '../bloc/appointment_bloc.dart';
import '../bloc/appointment_event.dart';
import '../bloc/appointment_state.dart';

enum _Filter { all, upcoming, completed, cancelled }

class AppointmentListPage extends StatefulWidget {
  const AppointmentListPage({super.key});

  @override
  State<AppointmentListPage> createState() => _AppointmentListPageState();
}

class _AppointmentListPageState extends State<AppointmentListPage> {
  _Filter _filter = _Filter.all;

  @override
  void initState() {
    super.initState();
    context.read<AppointmentBloc>().add(AppointmentsLoaded());
  }

  List<MyAppointmentDto> _apply(List<MyAppointmentDto> source) {
    switch (_filter) {
      case _Filter.all:
        return source;
      case _Filter.upcoming:
        return source
            .where((a) => a.status == AppointmentStatus.Scheduled)
            .toList();
      case _Filter.completed:
        return source
            .where((a) => a.status == AppointmentStatus.Completed)
            .toList();
      case _Filter.cancelled:
        return source
            .where((a) => a.status == AppointmentStatus.Cancelled)
            .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mint,
      appBar: AppBar(
        title: const Text('Appointments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.of(context).pushNamed('/appointments/book'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Book'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    active: _filter == _Filter.all,
                    onTap: () => setState(() => _filter = _Filter.all),
                  ),
                  _FilterChip(
                    label: 'Upcoming',
                    active: _filter == _Filter.upcoming,
                    onTap: () => setState(() => _filter = _Filter.upcoming),
                  ),
                  _FilterChip(
                    label: 'Completed',
                    active: _filter == _Filter.completed,
                    onTap: () => setState(() => _filter = _Filter.completed),
                  ),
                  _FilterChip(
                    label: 'Cancelled',
                    active: _filter == _Filter.cancelled,
                    onTap: () => setState(() => _filter = _Filter.cancelled),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: BlocConsumer<AppointmentBloc, AppointmentState>(
              listener: (context, state) {
                if (state is AppointmentError) {
                  TopNotification.show(
                    context,
                    state.message,
                    type: NotificationType.error,
                  );
                }
                if (state is AppointmentCancelledSuccess) {
                  TopNotification.show(
                    context,
                    'Appointment cancelled',
                    type: NotificationType.success,
                  );
                }
              },
              builder: (context, state) {
                if (state is AppointmentLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }
                if (state is AppointmentListLoaded) {
                  final list = _apply(state.appointments);
                  if (list.isEmpty) {
                    return const _EmptyState();
                  }
                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async {
                      context
                          .read<AppointmentBloc>()
                          .add(AppointmentsLoaded());
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                      itemCount: list.length,
                      itemBuilder: (context, index) =>
                          _AppointmentCard(appointment: list[index]),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.15),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.calendar_today_rounded,
              size: 36,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No appointments here',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Try another filter or book a new one.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final MyAppointmentDto appointment;

  const _AppointmentCard({required this.appointment});

  ({Color bg, Color fg, String label}) _statusStyle(AppointmentStatus s) {
    switch (s) {
      case AppointmentStatus.Scheduled:
        return (
          bg: AppColors.info.withValues(alpha: 0.12),
          fg: AppColors.info,
          label: 'Scheduled',
        );
      case AppointmentStatus.Completed:
        return (
          bg: AppColors.success.withValues(alpha: 0.12),
          fg: AppColors.success,
          label: 'Completed',
        );
      case AppointmentStatus.Cancelled:
        return (
          bg: AppColors.error.withValues(alpha: 0.12),
          fg: AppColors.error,
          label: 'Cancelled',
        );
      case AppointmentStatus.Rescheduled:
        return (
          bg: AppColors.warning.withValues(alpha: 0.12),
          fg: AppColors.warning,
          label: 'Rescheduled',
        );
      default:
        return (
          bg: AppColors.textSecondary.withValues(alpha: 0.12),
          fg: AppColors.textSecondary,
          label: s.name,
        );
    }
  }

  String _formatTime(String? startTime, String? endTime) {
    if (startTime == null) return '';
    try {
      final start = DateFormat('HH:mm:ss').parse(startTime);
      final startStr = DateFormat('h:mm a').format(start);
      if (endTime == null) return startStr;
      final end = DateFormat('HH:mm:ss').parse(endTime);
      return '$startStr – ${DateFormat('h:mm a').format(end)}';
    } catch (_) {
      return startTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime? date;
    try {
      date = DateTime.parse(appointment.appointmentDate);
    } catch (_) {}

    final dayLabel = date != null ? DateFormat('d').format(date) : '–';
    final monLabel = date != null
        ? DateFormat('MMM').format(date).toUpperCase()
        : '';
    final fullDate = date != null
        ? DateFormat('EEEE, d MMM').format(date)
        : appointment.appointmentDate;
    final style = _statusStyle(appointment.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => Navigator.of(
          context,
        ).pushNamed('/appointments/detail', arguments: appointment),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date block
              Container(
                width: 58,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      dayLabel,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      monLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            appointment.doctorName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: style.bg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            style.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: style.fg,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (appointment.doctorSpecialization.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        appointment.doctorSpecialization,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '$fullDate • '
                            '${_formatTime(appointment.startTime, appointment.endTime)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (appointment.appointmentTypeLabel.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            appointment.channel == AppointmentChannel.Online
                                ? Icons.videocam_rounded
                                : appointment.channel ==
                                          AppointmentChannel.Emergency
                                    ? Icons.local_hospital_rounded
                                    : Icons.location_on_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            appointment.appointmentTypeLabel,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
