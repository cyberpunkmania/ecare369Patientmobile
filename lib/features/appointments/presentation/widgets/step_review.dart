import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/theme_config.dart';
import '../bloc/booking_cubit.dart';
import '../bloc/booking_state.dart';

/// Step 3 – Review the booking details and confirm.
class StepReview extends StatefulWidget {
  const StepReview({super.key});

  @override
  State<StepReview> createState() => _StepReviewState();
}

class _StepReviewState extends State<StepReview> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingWizardCubit, BookingWizardState>(
      builder: (context, state) {
        final cubit = context.read<BookingWizardCubit>();
        final doctor = state.selectedDoctor;
        final slot = state.selectedSlot;
        final hold = state.slotHold;

        if (doctor == null || slot == null) {
          return const Center(child: Text('Missing booking details'));
        }

        final dateTime = DateTime.tryParse(slot.date);
        final dateLabel = dateTime != null
            ? DateFormat('EEEE, MMM d, yyyy').format(dateTime)
            : slot.date;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Hold timer ──
              if (hold != null)
                _HoldTimerBanner(secondsRemaining: state.holdSecondsRemaining),

              const SizedBox(height: 12),

              // ── Summary card ──
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Appointment Summary',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Divider(height: 24),
                      _InfoRow(label: 'Doctor', value: doctor.doctorName),
                      _InfoRow(
                        label: 'Specialty',
                        value: doctor.specialization,
                      ),
                      _InfoRow(label: 'Date', value: dateLabel),
                      _InfoRow(
                        label: 'Time',
                        value:
                            '${_fmtTime(slot.startTime)} – ${_fmtTime(slot.endTime)}',
                      ),
                      _InfoRow(
                        label: 'Fee',
                        value:
                            '${doctor.currency} ${doctor.consultationFee.toStringAsFixed(0)}',
                      ),
                      if (state.patientProfile != null) ...[
                        _InfoRow(
                          label: 'Patient',
                          value: state.patientProfile!.displayName,
                        ),
                        if ((state.patientProfile!.outpatientNumber ?? '')
                            .isNotEmpty)
                          _InfoRow(
                            label: 'OPD No.',
                            value: state.patientProfile!.outpatientNumber ?? '',
                          ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Reason for visit ──
              TextField(
                controller: _reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Reason for visit (optional)',
                  hintText: 'Briefly describe your symptoms…',
                  alignLabelWithHint: true,
                ),
                onChanged: cubit.setReasonForVisit,
              ),

              const SizedBox(height: 24),

              // ── Continue to payment ──
              ElevatedButton.icon(
                onPressed: state.isLoading ? null : cubit.proceedToPayment,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Continue to Payment'),
              ),
            ],
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

// ─────────────────────────────────────────────────────────────
// Info row
// ─────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
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
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Hold timer banner
// ─────────────────────────────────────────────────────────────

class _HoldTimerBanner extends StatelessWidget {
  final int secondsRemaining;

  const _HoldTimerBanner({required this.secondsRemaining});

  @override
  Widget build(BuildContext context) {
    final minutes = secondsRemaining ~/ 60;
    final seconds = secondsRemaining % 60;
    final isWarning = secondsRemaining < 120;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isWarning
            ? AppColors.warning.withValues(alpha: 0.12)
            : AppColors.info.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.timer,
            size: 18,
            color: isWarning ? AppColors.warning : AppColors.info,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Slot held for $minutes:${seconds.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isWarning ? AppColors.warning : AppColors.info,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
