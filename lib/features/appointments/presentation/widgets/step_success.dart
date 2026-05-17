import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/theme_config.dart';
import '../bloc/booking_cubit.dart';
import '../bloc/booking_state.dart';

/// Step 4 – Booking confirmed. Shows a success message with summary.
class StepSuccess extends StatelessWidget {
  const StepSuccess({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingWizardCubit, BookingWizardState>(
      builder: (context, state) {
        final doctor = state.selectedDoctor;
        final slot = state.selectedSlot;
        final dateTime = DateTime.tryParse(slot?.date ?? '');
        final dateLabel = dateTime != null
            ? DateFormat('EEEE, MMM d, yyyy').format(dateTime)
            : slot?.date ?? '';

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),

                // ── Check icon ──
                const CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.success,
                  child: Icon(Icons.check, size: 48, color: Colors.white),
                ),
                const SizedBox(height: 24),

                Text(
                  'Appointment Confirmed!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your appointment has been booked successfully.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 24),

                // ── Summary card ──
                if (doctor != null && slot != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _Row(icon: Icons.person, label: doctor.doctorName),
                          _Row(
                            icon: Icons.medical_services,
                            label: doctor.specialization,
                          ),
                          _Row(icon: Icons.calendar_today, label: dateLabel),
                          _Row(
                            icon: Icons.access_time,
                            label:
                                '${_fmtTime(slot.startTime)} – ${_fmtTime(slot.endTime)}',
                          ),
                          if (state.bookingConfirmedId != null)
                            _Row(
                              icon: Icons.confirmation_number,
                              label: 'Ref: ${state.bookingConfirmedId}',
                            ),
                        ],
                      ),
                    ),
                  ),

                const Spacer(),

                // ── Action buttons ──
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    context.read<BookingWizardCubit>().resetWizard();
                    context.read<BookingWizardCubit>().loadPatientProfile();
                    context.read<BookingWizardCubit>().loadDoctors();
                  },
                  child: const Text('Book Another Appointment'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _fmtTime(String time) {
    try {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = parts[1];
      final period = hour >= 12 ? 'PM' : 'AM';
      final h12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$h12:$minute $period';
    } catch (_) {
      return time;
    }
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Row({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
