import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/theme_config.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/public_tenant_entity.dart';
import '../bloc/tenant_cubit.dart';

/// "Select your clinic group" screen — shown before a patient self-registers.
///
/// Loads the list of active tenants from `GET /api/tenants/public`, lets the
/// user search + pick one, persists the selection to secure storage, and
/// returns the chosen [PublicTenantEntity] to the caller via `Navigator.pop`.
class TenantSelectPage extends StatelessWidget {
  /// Optional copy shown above the list explaining why we need the selection.
  final String? subtitle;

  /// CTA label on the bottom button. Defaults to "Continue".
  final String continueLabel;

  const TenantSelectPage({
    super.key,
    this.subtitle,
    this.continueLabel = 'Continue',
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TenantCubit>(
      create: (_) => sl<TenantCubit>()..load(),
      child: const _TenantSelectView(),
    );
  }
}

class _TenantSelectView extends StatelessWidget {
  const _TenantSelectView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mint,
      appBar: AppBar(
        title: const Text('Choose your clinic'),
        backgroundColor: AppColors.mint,
        elevation: 0,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final isCompact = w < 360;
            final isTablet = w >= 600;
            final horizontalPad = isCompact ? 16.0 : (isTablet ? 32.0 : 20.0);
            final contentMaxWidth = isTablet ? 640.0 : double.infinity;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentMaxWidth),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPad),
                  child: BlocBuilder<TenantCubit, TenantState>(
                    builder: (context, state) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 16),
                          _Header(
                            title: 'Pick your clinic group',
                            subtitle:
                                'We\'ll send your registration to the '
                                'right team and pre-fill clinic-specific options.',
                            isCompact: isCompact,
                          ),
                          const SizedBox(height: 20),
                          _SearchBox(
                            initial: state.query,
                            onChanged: (v) =>
                                context.read<TenantCubit>().search(v),
                          ),
                          const SizedBox(height: 12),
                          Expanded(child: _Body(state: state)),
                          _BottomBar(
                            enabled:
                                !state.loading && state.selectedTenant != null,
                            onTap: () async {
                              final tenant = await context
                                  .read<TenantCubit>()
                                  .confirmSelection();
                              if (tenant != null && context.mounted) {
                                Navigator.pop(context, tenant);
                              }
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Header
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isCompact;

  const _Header({
    required this.title,
    required this.subtitle,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: isCompact ? 20 : 24,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Search
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBox extends StatelessWidget {
  final String initial;
  final ValueChanged<String> onChanged;

  const _SearchBox({required this.initial, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: TextEditingController(text: initial)
        ..selection = TextSelection.collapsed(offset: initial.length),
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search_rounded),
        hintText: 'Search by name or code',
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Body / states
// ─────────────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final TenantState state;

  const _Body({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.loading && state.tenants.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.errorMessage != null && state.tenants.isEmpty) {
      return _ErrorView(
        message: state.errorMessage!,
        onRetry: () => context.read<TenantCubit>().load(),
      );
    }

    final list = state.visibleTenants;
    if (list.isEmpty) {
      return const _EmptyView();
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final tenant = list[i];
        final selected = tenant.id == state.selectedTenantId;
        return _TenantCard(
          tenant: tenant,
          selected: selected,
          onTap: () => context.read<TenantCubit>().select(tenant.id),
        );
      },
    );
  }
}

class _TenantCard extends StatelessWidget {
  final PublicTenantEntity tenant;
  final bool selected;
  final VoidCallback onTap;

  const _TenantCard({
    required this.tenant,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = selected
        ? Border.all(color: AppColors.primary, width: 2)
        : Border.all(color: Colors.transparent);
    final bg = selected
        ? AppColors.mintDeep.withValues(alpha: 0.35)
        : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(22),
            border: border,
          ),
          child: Row(
            children: [
              _Avatar(tenant: tenant),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tenant.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _Pill(text: tenant.code),
                        _Pill(text: tenant.type),
                        if (tenant.hasMultipleBranches)
                          const _Pill(text: 'Multiple branches'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.textHint,
                    width: 2,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final PublicTenantEntity tenant;

  const _Avatar({required this.tenant});

  @override
  Widget build(BuildContext context) {
    final letter = tenant.name.isNotEmpty ? tenant.name[0].toUpperCase() : '?';
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: tenant.logoUrl != null && tenant.logoUrl!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                tenant.logoUrl!,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _Letter(letter: letter),
              ),
            )
          : _Letter(letter: letter),
    );
  }
}

class _Letter extends StatelessWidget {
  final String letter;
  const _Letter({required this.letter});

  @override
  Widget build(BuildContext context) {
    return Text(
      letter,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  const _Pill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Empty / Error
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 56,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 12),
          Text(
            'No clinics match your search.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 56, color: AppColors.error),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Bottom CTA
// ─────────────────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _BottomBar({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: enabled ? onTap : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.primary.withValues(
                alpha: 0.35,
              ),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: const Text(
              'Continue',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}
