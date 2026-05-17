import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/theme_config.dart';
import '../../data/models/appointment_slot_dto.dart';
import '../bloc/booking_cubit.dart';
import '../bloc/booking_state.dart';

/// Step 2 – Pick a time slot from the day's available slots.
class StepTimeSlots extends StatelessWidget {
  const StepTimeSlots({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingWizardCubit, BookingWizardState>(
      builder: (context, state) {
        final cubit = context.read<BookingWizardCubit>();
        final dateTime = DateTime.tryParse(state.selectedDate ?? '');
        final dateLabel = dateTime != null
            ? DateFormat('EEEE, MMM d').format(dateTime)
            : state.selectedDate ?? '';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Date & doctor header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dateLabel,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (state.selectedDoctor != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${state.selectedDoctor!.doctorName}  •  ${state.selectedDoctor!.specialization}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const Divider(height: 24),

            // ── Label ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Available times',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),

            // ── Slot grid ──
            Expanded(
              child: state.daySlots.isEmpty && !state.isLoading
                  ? const Center(
                      child: Text(
                        'No bookable slots for this day',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 2.4,
                          ),
                      itemCount: state.daySlots.length,
                      itemBuilder: (context, index) {
                        final slot = state.daySlots[index];
                        final isSelected = state.selectedSlot?.id == slot.id;
                        final isHeld = slot.status == SlotStatus.OnHold;
                        return _SlotChip(
                          slot: slot,
                          isSelected: isSelected,
                          isDisabled: isHeld,
                          onTap: isHeld ? null : () => cubit.selectSlot(slot),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Slot chip
// ─────────────────────────────────────────────────────────────

class _SlotChip extends StatelessWidget {
  final AppointmentSlotDto slot;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback? onTap;

  const _SlotChip({
    required this.slot,
    required this.isSelected,
    required this.onTap,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    if (isSelected) {
      bg = AppColors.primary;
      fg = Colors.white;
    } else if (isDisabled) {
      bg = AppColors.textHint.withValues(alpha: 0.12);
      fg = AppColors.textHint;
    } else {
      bg = AppColors.primaryLight.withValues(alpha: 0.1);
      fg = AppColors.primary;
    }

    return Tooltip(
      message: isDisabled ? 'On hold by another patient' : '',
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatTime(slot.startTime),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: fg,
                    decoration: isDisabled
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                if (isDisabled)
                  Text(
                    'On hold',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: fg,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(String time) {
    // Input: "09:00" or "14:30"
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
