import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/theme_config.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/top_notification.dart';
import '../../domain/entities/patient_profile_entity.dart';
import '../bloc/profile_cubit.dart';
import '../widgets/demographics_edit_sheet.dart';
import '../widgets/emergency_contact_edit_sheet.dart';
import '../widgets/insurance_edit_sheet.dart';

/// Patient profile screen — `me + demographics + emergency contact + insurance`.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfileCubit>(
      create: (_) => sl<ProfileCubit>()..load(),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileState>(
      listenWhen: (p, n) =>
          p.errorMessage != n.errorMessage ||
          p.successMessage != n.successMessage,
      listener: (context, state) {
        if (state.errorMessage != null) {
          TopNotification.show(
            context,
            state.errorMessage!,
            type: NotificationType.error,
          );
          context.read<ProfileCubit>().clearMessages();
        } else if (state.successMessage != null) {
          TopNotification.show(
            context,
            state.successMessage!,
            type: NotificationType.success,
          );
          context.read<ProfileCubit>().clearMessages();
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.mint,
          appBar: AppBar(
            title: const Text('My profile'),
            backgroundColor: AppColors.mint,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            scrolledUnderElevation: 0,
            actions: [
              IconButton(
                tooltip: 'Refresh',
                onPressed: state.loading
                    ? null
                    : () => context.read<ProfileCubit>().load(),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final isCompact = width < 360;
                final isTablet = width >= 600;
                final horizontalPad = isTablet
                    ? 32.0
                    : (isCompact ? 16.0 : 20.0);
                const maxWidth = 720.0;

                if (state.loading && state.profile == null) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                final profile = state.profile;
                if (profile == null) {
                  return _ErrorOrEmpty(
                    message:
                        state.errorMessage ?? 'We could not load your profile.',
                    onRetry: () => context.read<ProfileCubit>().load(),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => context.read<ProfileCubit>().load(),
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPad,
                      8,
                      horizontalPad,
                      40,
                    ),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: isTablet ? maxWidth : double.infinity,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _HeaderCard(profile: profile, compact: isCompact),
                              const SizedBox(height: 18),
                              _DemographicsCard(profile: profile),
                              const SizedBox(height: 14),
                              _EmergencyContactCard(profile: profile),
                              const SizedBox(height: 14),
                              _InsuranceCard(profile: profile),
                              if (state.saving)
                                const Padding(
                                  padding: EdgeInsets.only(top: 16),
                                  child: LinearProgressIndicator(
                                    minHeight: 2,
                                    color: AppColors.primary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final PatientProfileEntity profile;
  final bool compact;
  const _HeaderCard({required this.profile, required this.compact});

  @override
  Widget build(BuildContext context) {
    final initials = _initialsOf(profile);
    return Container(
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF0FB8A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: compact ? 28 : 34,
            backgroundColor: Colors.white,
            child: Text(
              initials,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: compact ? 18 : 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.fullName,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 18 : 20,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  profile.email,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (profile.phoneNumber.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    profile.phoneNumber,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initialsOf(PatientProfileEntity p) {
    final f = p.firstName.isNotEmpty ? p.firstName[0] : '';
    final l = p.lastName.isNotEmpty ? p.lastName[0] : '';
    final joined = '$f$l';
    return joined.isEmpty ? '?' : joined.toUpperCase();
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final VoidCallback? onEdit;
  final String editLabel;
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.onEdit,
    this.editLabel = 'Edit',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.mintDeep.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (onEdit != null)
                TextButton.icon(
                  onPressed: onEdit,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                  ),
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: Text(
                    editLabel,
                    style: const TextStyle(fontWeight: FontWeight.w600),
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

class _KeyValue extends StatelessWidget {
  final String label;
  final String value;
  const _KeyValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DemographicsCard extends StatelessWidget {
  final PatientProfileEntity profile;
  const _DemographicsCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final dob = profile.dateOfBirth;
    final dobStr = dob == null
        ? ''
        : '${DateFormat('d MMM yyyy').format(dob)}'
              '${profile.age != null ? ' · ${profile.age} yrs' : ''}';
    final address = [
      profile.addressLine1,
      profile.addressLine2,
      profile.city,
      profile.country,
    ].whereType<String>().where((s) => s.isNotEmpty).join(', ');

    return _SectionCard(
      title: 'Demographics',
      icon: Icons.badge_outlined,
      onEdit: () async {
        final cubit = context.read<ProfileCubit>();
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => DemographicsEditSheet(
            initial: profile,
            onSave: cubit.updateDemographics,
          ),
        );
      },
      child: Column(
        children: [
          _KeyValue(label: 'Date of birth', value: dobStr),
          _KeyValue(label: 'Gender', value: profile.gender ?? ''),
          _KeyValue(label: 'Address', value: address),
        ],
      ),
    );
  }
}

class _EmergencyContactCard extends StatelessWidget {
  final PatientProfileEntity profile;
  const _EmergencyContactCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final c = profile.emergencyContact;
    return _SectionCard(
      title: 'Emergency contact',
      icon: Icons.contact_phone_outlined,
      onEdit: () async {
        final cubit = context.read<ProfileCubit>();
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => EmergencyContactEditSheet(
            initial: c,
            onSave: cubit.updateEmergencyContact,
          ),
        );
      },
      child: c == null
          ? const Text(
              'Add a person we can reach in case of emergency.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            )
          : Column(
              children: [
                _KeyValue(label: 'Name', value: c.name),
                _KeyValue(label: 'Relationship', value: c.relationship),
                _KeyValue(label: 'Phone', value: c.phoneNumber),
                if (c.email != null) _KeyValue(label: 'Email', value: c.email!),
              ],
            ),
    );
  }
}

class _InsuranceCard extends StatelessWidget {
  final PatientProfileEntity profile;
  const _InsuranceCard({required this.profile});

  void _openAddSheet(BuildContext context) {
    final cubit = context.read<ProfileCubit>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InsuranceAddSheet(onAdd: cubit.addInsurance),
    );
  }

  void _openEditSheet(BuildContext context, ins) {
    final cubit = context.read<ProfileCubit>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InsuranceAddSheet(
        initialInsurance: ins,
        onUpdate: cubit.updateInsurance,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Insurance',
      icon: Icons.health_and_safety_outlined,
      editLabel: 'Add',
      onEdit: () => _openAddSheet(context),
      child: profile.insurances.isEmpty
          ? const Text(
              'No insurance policies on file yet.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            )
          : Column(
              children: [
                for (final ins in profile.insurances)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.mint.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      ins.providerName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  if (ins.isPrimary)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        'Primary',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              if (ins.schemeName != null)
                                Text(
                                  ins.schemeName!,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                'Policy: ${ins.policyNumber}',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Edit button
                        IconButton(
                          tooltip: 'Edit',
                          onPressed: () => _openEditSheet(context, ins),
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        // Delete button — no confirmation modal
                        IconButton(
                          tooltip: 'Remove',
                          onPressed: () => context
                              .read<ProfileCubit>()
                              .removeInsurance(ins.id),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _ErrorOrEmpty extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorOrEmpty({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 64,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: onRetry,
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}
