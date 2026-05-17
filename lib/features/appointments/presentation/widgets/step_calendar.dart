import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/theme_config.dart';
import '../../data/models/doctor_available_slots_dto.dart';
import '../bloc/booking_cubit.dart';
import '../bloc/booking_state.dart';

/// Step 1 – Pick a date from a week calendar strip.
class StepCalendar extends StatelessWidget {
  const StepCalendar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingWizardCubit, BookingWizardState>(
      builder: (context, state) {
        final cubit = context.read<BookingWizardCubit>();
        final doctor = state.selectedDoctor;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Doctor summary chip ──
            if (doctor != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${doctor.doctorName}  •  ${doctor.specialization}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // ── Week navigation ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: cubit.loadPreviousWeek,
                  ),
                  Text(
                    _weekLabel(state.weekSlots),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: cubit.loadNextWeek,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Day cards ──
            Expanded(
              child: state.weekSlots.isEmpty && !state.isLoading
                  ? const Center(
                      child: Text(
                        'No schedule available for this week',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      itemCount: state.weekSlots.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final day = state.weekSlots[index];
                        return _DayCard(
                          day: day,
                          isSelected: state.selectedDate == day.date,
                          onTap: day.totalAvailable > 0
                              ? () => cubit.selectDate(day.date)
                              : null,
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  String _weekLabel(List<DoctorAvailableSlotsDto> slots) {
    if (slots.isEmpty) return '';
    final fmt = DateFormat('MMM d');
    try {
      final first = DateTime.parse(slots.first.date);
      final last = DateTime.parse(slots.last.date);
      return '${fmt.format(first)} – ${fmt.format(last)}';
    } catch (_) {
      return '';
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Day card
// ─────────────────────────────────────────────────────────────

class _DayCard extends StatelessWidget {
  final DoctorAvailableSlotsDto day;
  final bool isSelected;
  final VoidCallback? onTap;

  const _DayCard({required this.day, required this.isSelected, this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = day.totalAvailable == 0;
    final dateTime = DateTime.tryParse(day.date);
    final dayName = dateTime != null ? DateFormat('EEEE').format(dateTime) : '';
    final dateLabel = dateTime != null
        ? DateFormat('MMM d, yyyy').format(dateTime)
        : day.date;

    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected
          ? AppColors.primaryLight.withValues(alpha: 0.15)
          : disabled
          ? AppColors.background
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? const BorderSide(color: AppColors.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Day name & date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dayName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: disabled
                            ? AppColors.textHint
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: disabled
                            ? AppColors.textHint
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Slot count badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: disabled
                      ? AppColors.textHint.withValues(alpha: 0.15)
                      : AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  disabled
                      ? 'Full'
                      : '${day.totalAvailable} slot${day.totalAvailable == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: disabled ? AppColors.textHint : AppColors.success,
                  ),
                ),
              ),

              if (!disabled) ...[
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: AppColors.textHint),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
