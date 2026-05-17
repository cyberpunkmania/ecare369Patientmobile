import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/theme_config.dart';
import '../../data/models/doctor_availability_dto.dart';
import '../bloc/booking_cubit.dart';
import '../bloc/booking_state.dart';

/// Step 0 – Browse & pick a doctor.
class StepDoctors extends StatefulWidget {
  const StepDoctors({super.key});

  @override
  State<StepDoctors> createState() => _StepDoctorsState();
}

class _StepDoctorsState extends State<StepDoctors> {
  final _searchController = TextEditingController();
  String? _selectedSpecialty;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingWizardCubit, BookingWizardState>(
      builder: (context, state) {
        // Derive distinct specialty list from loaded doctors.
        final specialties =
            state.doctors
                .map((d) => d.specialty)
                .where((s) => s.isNotEmpty)
                .toSet()
                .toList()
              ..sort();

        // Filter locally by search text.
        final query = _searchController.text.toLowerCase();
        var filtered = state.doctors.where((d) {
          if (query.isNotEmpty &&
              !d.doctorName.toLowerCase().contains(query) &&
              !d.specialization.toLowerCase().contains(query)) {
            return false;
          }
          if (_selectedSpecialty != null && d.specialty != _selectedSpecialty) {
            return false;
          }
          return true;
        }).toList();

        return Column(
          children: [
            // ── Search bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search doctor or specialty…',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),

            // ── Online-only toggle ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.wifi, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Online booking only',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  Switch.adaptive(
                    value: state.onlineOnly,
                    onChanged: (val) {
                      context.read<BookingWizardCubit>().loadDoctors(
                        onlineOnly: val,
                      );
                    },
                  ),
                ],
              ),
            ),

            // ── Specialty chips ──
            if (specialties.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: specialties.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return ChoiceChip(
                          label: const Text('All'),
                          selected: _selectedSpecialty == null,
                          onSelected: (_) =>
                              setState(() => _selectedSpecialty = null),
                        );
                      }
                      final spec = specialties[index - 1];
                      return ChoiceChip(
                        label: Text(spec),
                        selected: _selectedSpecialty == spec,
                        onSelected: (_) => setState(
                          () => _selectedSpecialty = _selectedSpecialty == spec
                              ? null
                              : spec,
                        ),
                      );
                    },
                  ),
                ),
              ),

            // ── Doctor list ──
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        state.isLoading ? '' : 'No doctors available',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async =>
                          context.read<BookingWizardCubit>().loadDoctors(),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) => _DoctorCard(
                          doctor: filtered[index],
                          onTap: () => context
                              .read<BookingWizardCubit>()
                              .selectDoctor(filtered[index]),
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Doctor card
// ─────────────────────────────────────────────────────────────

class _DoctorCard extends StatelessWidget {
  final DoctorAvailabilityDto doctor;
  final VoidCallback onTap;

  const _DoctorCard({required this.doctor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
                backgroundImage: doctor.profilePhotoUrl != null
                    ? NetworkImage(doctor.profilePhotoUrl!)
                    : null,
                child: doctor.profilePhotoUrl == null
                    ? Text(
                        _initials(doctor.doctorName),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.doctorName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      doctor.specialization,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (doctor.yearsOfExperience > 0) ...[
                          _badge(
                            '${doctor.yearsOfExperience}y exp',
                            AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                        ] else if (doctor.availableSlotCount > 0) ...[
                          _badge(
                            '${doctor.availableSlotCount} slots',
                            doctor.isAtCapacity
                                ? AppColors.error
                                : AppColors.success,
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (doctor.consultationFee > 0)
                          Text(
                            '${doctor.currency} ${doctor.consultationFee.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const Icon(Icons.chevron_right, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts.isNotEmpty ? parts[0][0].toUpperCase() : '?';
  }
}
