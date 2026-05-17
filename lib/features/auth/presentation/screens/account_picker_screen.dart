import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/theme_config.dart';
import '../../domain/entities/account_option_entity.dart';
import '../../domain/entities/lookup_result_entity.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';

/// Screen for selecting an account when multiple accounts are found.
class AccountPickerScreen extends StatelessWidget {
  final String email;
  final LookupResultEntity lookupResult;

  const AccountPickerScreen({
    super.key,
    required this.email,
    required this.lookupResult,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),

          // ── Back Button ──
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                context.read<AuthBloc>().add(const AuthResetRequested());
              },
            ),
          ),
          const SizedBox(height: 16),

          // ── Header ──
          Text(
            'Select Account',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'We found multiple accounts for $email. Please select one to continue.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),

          // ── Active Accounts Section ──
          if (lookupResult.canLoginAccounts.isNotEmpty) ...[
            _SectionHeader(
              title: 'Active Accounts',
              subtitle: 'Ready to login',
              icon: Icons.check_circle_outline,
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            ...lookupResult.canLoginAccounts.map(
              (account) => _AccountTile(
                account: account,
                onTap: () => _selectAccount(context, account),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // ── Onboarding Accounts Section ──
          if (lookupResult.onboardingAccounts.isNotEmpty) ...[
            _SectionHeader(
              title: 'New Accounts',
              subtitle: 'Complete your setup',
              icon: Icons.person_add_outlined,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            ...lookupResult.onboardingAccounts.map(
              (account) => _AccountTile(
                account: account,
                onTap: () => _selectAccount(context, account),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // ── Inactive Accounts Section ──
          if (lookupResult.inactiveAccounts.isNotEmpty) ...[
            _SectionHeader(
              title: 'Inactive Accounts',
              subtitle: 'Reactivation required',
              icon: Icons.pause_circle_outline,
              color: Colors.orange,
            ),
            const SizedBox(height: 12),
            ...lookupResult.inactiveAccounts.map(
              (account) => _AccountTile(
                account: account,
                onTap: () => _selectAccount(context, account),
              ),
            ),
            const SizedBox(height: 24),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _selectAccount(BuildContext context, AccountOptionEntity account) {
    context.read<AuthBloc>().add(AccountSelected(account: account));
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }
}

class _AccountTile extends StatelessWidget {
  final AccountOptionEntity account;
  final VoidCallback onTap;

  const _AccountTile({required this.account, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(
            account.status,
          ).withValues(alpha: 0.1),
          child: Icon(
            _getAccountIcon(account.accountType),
            color: _getStatusColor(account.status),
          ),
        ),
        title: Text(
          account.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(account.accountType.displayName),
            if (account.subtitle != null)
              Text(
                account.subtitle!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
          ],
        ),
        trailing: Icon(Icons.chevron_right, color: AppColors.textSecondary),
        isThreeLine: account.subtitle != null,
      ),
    );
  }

  Color _getStatusColor(AccountStatus status) {
    switch (status) {
      case AccountStatus.active:
        return Colors.green;
      case AccountStatus.onboarding:
        return AppColors.primary;
      case AccountStatus.inactive:
        return Colors.orange;
    }
  }

  IconData _getAccountIcon(AccountType type) {
    switch (type) {
      case AccountType.platformPatient:
      case AccountType.tenantPatient:
        return Icons.person_outline;
      case AccountType.platformDoctor:
      case AccountType.tenantDoctor:
        return Icons.medical_services_outlined;
      case AccountType.platformAdmin:
      case AccountType.tenantAdmin:
        return Icons.admin_panel_settings_outlined;
    }
  }
}
