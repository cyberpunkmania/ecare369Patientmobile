import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/theme_config.dart';
import '../../../../core/connectivity/connectivity_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/widgets/pill_bottom_nav.dart';
import '../../../../routes/app_router.dart';
import '../../../appointments/data/models/my_appointment_dto.dart';
import '../../../appointments/presentation/bloc/appointment_bloc.dart';
import '../../../appointments/presentation/bloc/appointment_event.dart';
import '../../../appointments/presentation/bloc/appointment_state.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../chat/presentation/pages/conversation_list_page.dart';

// ─────────────────────────────────────────────────────────────
// Dashboard shell – sleek pill-style bottom nav + swipeable pages
// ─────────────────────────────────────────────────────────────

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final PageController _pageController;
  int _currentIndex = 0;

  static const _navItems = <PillNavItem>[
    PillNavItem(icon: Icons.home_rounded, label: 'Home'),
    PillNavItem(icon: Icons.medical_services_rounded, label: 'Doctors'),
    PillNavItem(icon: Icons.event_note_rounded, label: 'Records'),
    PillNavItem(icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) => setState(() => _currentIndex = index);

  void _onNavTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(Routes.auth, (_) => false);
        }
      },
      child: Scaffold(
        extendBody: true,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              BlocBuilder<ConnectivityBloc, ConnectivityState>(
                builder: (context, state) {
                  if (state is ConnectivityOffline) {
                    return Container(
                      width: double.infinity,
                      color: AppColors.warning,
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 16,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.wifi_off, color: Colors.white, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'You are offline',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  children: [
                    const _HomeTab(),
                    const _DoctorsTab(),
                    BlocProvider<AppointmentBloc>(
                      create: (_) =>
                          sl<AppointmentBloc>()..add(AppointmentsLoaded()),
                      child: const _RecordsTab(),
                    ),
                    const _ProfileTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: PillBottomNav(
          items: _navItems,
          currentIndex: _currentIndex,
          onTap: _onNavTapped,
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// HOME TAB
// ═════════════════════════════════════════════════════════════

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AppointmentBloc>(
      create: (_) => sl<AppointmentBloc>()..add(AppointmentsLoaded()),
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final user = authState is AuthAuthenticated ? authState.user : null;
          final greetingName = user?.firstName.isNotEmpty == true
              ? user!.firstName
              : (user?.name ?? 'there');
          final dateLabel = DateFormat('d MMMM, y').format(DateTime.now());

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async =>
                context.read<AppointmentBloc>().add(AppointmentsLoaded()),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              children: [
                _GreetingHeader(name: greetingName, date: dateLabel),
                const SizedBox(height: 22),
                _SectionHeader(
                  title: 'Top Doctors',
                  trailingLabel: 'See all',
                  onTrailingTap: () =>
                      DefaultTabController.maybeOf(context)?.animateTo(1),
                ),
                const SizedBox(height: 12),
                BlocBuilder<AppointmentBloc, AppointmentState>(
                  builder: (context, state) {
                    if (state is AppointmentListLoaded &&
                        state.appointments.isNotEmpty) {
                      return _FeaturedAppointmentCard(
                        appointment: state.appointments.first,
                      );
                    }
                    return const _FeaturedPlaceholderCard();
                  },
                ),
                const SizedBox(height: 26),
                _SectionHeader(
                  title: 'Health monitoring',
                  trailingIcon: Icons.tune_rounded,
                ),
                const SizedBox(height: 12),
                _MonitoringGrid(
                  onMedicalRecords: () =>
                      Navigator.of(context).pushNamed(Routes.medicalRecords),
                  onNotifications: () =>
                      Navigator.of(context).pushNamed(Routes.notifications),
                ),
                const SizedBox(height: 26),
                _SectionHeader(title: 'Upcoming'),
                const SizedBox(height: 12),
                BlocBuilder<AppointmentBloc, AppointmentState>(
                  builder: (context, state) {
                    if (state is AppointmentLoading) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    }
                    if (state is AppointmentListLoaded) {
                      final upcoming = state.appointments.take(3);
                      if (upcoming.isEmpty) {
                        return const _EmptyAppointmentsTile();
                      }
                      return Column(
                        children: upcoming
                            .map(
                              (a) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _AppointmentMiniTile(appointment: a),
                              ),
                            )
                            .toList(),
                      );
                    }
                    return const _EmptyAppointmentsTile();
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Greeting header (avatar + name + date + actions) ────────

class _GreetingHeader extends StatelessWidget {
  final String name;
  final String date;
  const _GreetingHeader({required this.name, required this.date});

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          alignment: Alignment.center,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, $name',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                date,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        _IconChip(icon: Icons.search_rounded, onTap: () {}),
        const SizedBox(width: 8),
        _IconChip(
          icon: Icons.notifications_none_rounded,
          showBadge: true,
          onTap: () => Navigator.of(context).pushNamed(Routes.notifications),
        ),
      ],
    );
  }
}

class _IconChip extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool showBadge;
  const _IconChip({
    required this.icon,
    required this.onTap,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 20, color: AppColors.textPrimary),
            if (showBadge)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? trailingLabel;
  final IconData? trailingIcon;
  final VoidCallback? onTrailingTap;
  const _SectionHeader({
    required this.title,
    this.trailingLabel,
    this.trailingIcon,
    this.onTrailingTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (trailingLabel != null)
          GestureDetector(
            onTap: onTrailingTap,
            child: Text(
              trailingLabel!,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        if (trailingIcon != null) ...[
          _IconChip(icon: trailingIcon!, onTap: onTrailingTap ?? () {}),
        ],
      ],
    );
  }
}

// ─── Featured doctor / appointment card (teal hero) ──────────

class _FeaturedAppointmentCard extends StatelessWidget {
  final MyAppointmentDto appointment;
  const _FeaturedAppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    DateTime? apptDate;
    try {
      apptDate = DateTime.parse(appointment.appointmentDate);
    } catch (_) {}

    return _HeroDoctorShell(
      specialty: appointment.doctorSpecialization,
      doctorName: appointment.doctorName,
      ratingLabel: 'Booked',
      priceLabel: appointment.startTime != null
          ? appointment.startTime!.substring(0, 5)
          : '—',
      monthLabel: apptDate != null
          ? DateFormat('MMMM y').format(apptDate)
          : 'Upcoming',
      activeDay: apptDate?.weekday ?? DateTime.now().weekday,
      onTap: () => Navigator.of(
        context,
      ).pushNamed(Routes.appointmentDetail, arguments: appointment),
    );
  }
}

class _FeaturedPlaceholderCard extends StatelessWidget {
  const _FeaturedPlaceholderCard();

  @override
  Widget build(BuildContext context) {
    return _HeroDoctorShell(
      specialty: 'Book a doctor',
      doctorName: 'Find the right care',
      ratingLabel: '★ 4.8',
      priceLabel: '8 slots',
      monthLabel: DateFormat('MMMM y').format(DateTime.now()),
      activeDay: DateTime.now().weekday,
      onTap: () => Navigator.of(context).pushNamed(Routes.bookAppointment),
    );
  }
}

class _HeroDoctorShell extends StatelessWidget {
  final String specialty;
  final String doctorName;
  final String ratingLabel;
  final String priceLabel;
  final String monthLabel;
  final int activeDay;
  final VoidCallback onTap;

  const _HeroDoctorShell({
    required this.specialty,
    required this.doctorName,
    required this.ratingLabel,
    required this.priceLabel,
    required this.monthLabel,
    required this.activeDay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dayLetters = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final today = DateTime.now();
    // Build a Mon..Sun strip rooted at this week's Monday.
    final weekStart = today.subtract(Duration(days: today.weekday - 1));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFF5A524),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ratingLabel,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.favorite_border_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              specialty,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              doctorName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              priceLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            // ── Availability strip ──
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text(
                        'Availability • 8 slots',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.chevron_left,
                        color: Colors.white,
                        size: 18,
                      ),
                      Text(
                        monthLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (i) {
                      final day = weekStart.add(Duration(days: i));
                      final isActive = (i + 1) == activeDay;
                      return Column(
                        children: [
                          Text(
                            dayLetters[i],
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 30,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.white
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              '${day.day}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isActive
                                    ? AppColors.primary
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Health monitoring grid ──────────────────────────────────

class _MonitoringGrid extends StatelessWidget {
  final VoidCallback onMedicalRecords;
  final VoidCallback onNotifications;
  const _MonitoringGrid({
    required this.onMedicalRecords,
    required this.onNotifications,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: _MonitoringTile(
              title: 'Medical\nrecords',
              icon: Icons.description_outlined,
              onTap: onMedicalRecords,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _MonitoringTile(
              title: 'Lab\nresults',
              icon: Icons.science_outlined,
              onTap: onNotifications,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonitoringTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  const _MonitoringTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 116,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Theme.of(context).colorScheme.onSurface,
                height: 1.1,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 18, color: AppColors.primary),
                ),
                const Spacer(),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.arrow_outward_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Appointment list row ────────────────────────────────────

class _AppointmentMiniTile extends StatelessWidget {
  final MyAppointmentDto appointment;
  const _AppointmentMiniTile({required this.appointment});

  @override
  Widget build(BuildContext context) {
    String dateLabel;
    try {
      final d = DateTime.parse(appointment.appointmentDate);
      dateLabel = DateFormat('EEE d MMM').format(d);
    } catch (_) {
      dateLabel = appointment.appointmentDate;
    }
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.of(
        context,
      ).pushNamed(Routes.appointmentDetail, arguments: appointment),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.medical_services_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.doctorName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$dateLabel • ${appointment.doctorSpecialization}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _EmptyAppointmentsTile extends StatelessWidget {
  const _EmptyAppointmentsTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.calendar_today_rounded,
            color: AppColors.primary,
            size: 36,
          ),
          const SizedBox(height: 8),
          const Text(
            'No upcoming appointments',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_rounded),
              label: const Text('Book Appointment'),
              onPressed: () =>
                  Navigator.of(context).pushNamed(Routes.bookAppointment),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// DOCTORS TAB  (routes to existing chat + booking entry points)
// ═════════════════════════════════════════════════════════════

class _DoctorsTab extends StatelessWidget {
  const _DoctorsTab();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          floating: true,
          elevation: 0,
          title: Text('Doctors'),
          automaticallyImplyLeading: false,
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search for doctor…',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textSecondary,
                  ),
                  suffixIcon: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.mint,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const _SectionHeader(title: 'Find a doctor'),
              const SizedBox(height: 12),
              _DoctorActionCard(
                title: 'Book a new appointment',
                subtitle: 'Browse specialists & schedules',
                icon: Icons.calendar_month_rounded,
                onTap: () =>
                    Navigator.of(context).pushNamed(Routes.bookAppointment),
              ),
              const SizedBox(height: 10),
              _DoctorActionCard(
                title: 'My appointments',
                subtitle: 'View, reschedule or cancel',
                icon: Icons.event_available_rounded,
                onTap: () =>
                    Navigator.of(context).pushNamed(Routes.appointments),
              ),
              const SizedBox(height: 10),
              _DoctorActionCard(
                title: 'Chat with my doctor',
                subtitle: 'Open conversations',
                icon: Icons.chat_bubble_rounded,
                onTap: () =>
                    Navigator.of(context).pushNamed(Routes.conversations),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _DoctorActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  const _DoctorActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.arrow_outward_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// RECORDS TAB  (appointments + medical records gateway)
// ═════════════════════════════════════════════════════════════

class _RecordsTab extends StatelessWidget {
  const _RecordsTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Records'),
        automaticallyImplyLeading: false,
      ),
      body: BlocBuilder<AppointmentBloc, AppointmentState>(
        builder: (context, state) {
          if (state is AppointmentLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (state is AppointmentError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    state.message,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.read<AppointmentBloc>().add(
                      AppointmentsLoaded(),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is AppointmentListLoaded) {
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                context.read<AppointmentBloc>().add(AppointmentsLoaded());
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                children: [
                  _DoctorActionCard(
                    title: 'Medical history',
                    subtitle: 'Diagnoses, prescriptions, allergies',
                    icon: Icons.folder_shared_rounded,
                    onTap: () =>
                        Navigator.of(context).pushNamed(Routes.medicalRecords),
                  ),
                  const SizedBox(height: 10),
                  _DoctorActionCard(
                    title: 'Notifications',
                    subtitle: 'Reminders and alerts',
                    icon: Icons.notifications_rounded,
                    onTap: () =>
                        Navigator.of(context).pushNamed(Routes.notifications),
                  ),
                  const SizedBox(height: 22),
                  const _SectionHeader(title: 'Appointments'),
                  const SizedBox(height: 12),
                  if (state.appointments.isEmpty)
                    const _EmptyAppointmentsTile()
                  else
                    ...state.appointments.map(
                      (a) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _AppointmentMiniTile(appointment: a),
                      ),
                    ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// PROFILE TAB
// ═════════════════════════════════════════════════════════════

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final user = authState is AuthAuthenticated ? authState.user : null;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded),
                onPressed: () =>
                    Navigator.of(context).pushNamed(Routes.notifications),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            children: [
              _ProfileHero(user: user),
              const SizedBox(height: 20),
              const _IdentityVerificationCard(percent: 0.8),
              const SizedBox(height: 20),
              const _SectionHeader(
                title: 'Information management',
                trailingLabel: 'See all',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _InfoStatCard(
                      title: 'Appointments',
                      value: 'Active',
                      hint: 'View your bookings',
                      filled: true,
                      onTap: () =>
                          Navigator.of(context).pushNamed(Routes.appointments),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _InfoStatCard(
                      title: 'My Doctors',
                      value: 'Online',
                      hint: 'Conversations',
                      onTap: () =>
                          Navigator.of(context).pushNamed(Routes.conversations),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const _SectionHeader(title: 'Settings'),
              const SizedBox(height: 12),
              _SettingsCard(
                children: [
                  _SettingTile(
                    icon: Icons.account_circle_outlined,
                    label: 'Account settings',
                    onTap: () =>
                        Navigator.of(context).pushNamed(Routes.profile),
                  ),
                  _SettingTile(
                    icon: Icons.brightness_6_outlined,
                    label: 'Dark mode',
                    trailing: Switch.adaptive(
                      activeThumbColor: Colors.white,
                      activeTrackColor: AppColors.primary,
                      value: Theme.of(context).brightness == Brightness.dark,
                      onChanged: (_) =>
                          context.read<ThemeCubit>().toggleTheme(),
                    ),
                  ),
                  _SettingTile(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    onTap: () =>
                        Navigator.of(context).pushNamed(Routes.notifications),
                  ),
                  _SettingTile(
                    icon: Icons.lock_outline,
                    label: 'Privacy & security',
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.logout, color: AppColors.error),
                  label: const Text('Log out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () =>
                      context.read<AuthBloc>().add(AuthLogoutRequested()),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final dynamic user; // UserEntity?, kept loose to avoid extra imports
  const _ProfileHero({required this.user});

  String _initials() {
    final f = (user?.firstName as String?)?.isNotEmpty == true
        ? (user!.firstName as String)[0]
        : '';
    final l = (user?.lastName as String?)?.isNotEmpty == true
        ? (user!.lastName as String)[0]
        : '';
    return (f + l).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final displayName = (user?.name as String?) ?? 'Patient';
    final email = (user?.email as String?) ?? '';
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                _initials().isEmpty ? 'P' : _initials(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          displayName,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        const SizedBox(height: 2),
        Text(
          email,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }
}

class _IdentityVerificationCard extends StatelessWidget {
  final double percent;
  const _IdentityVerificationCard({required this.percent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Identity Verification',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '${(percent * 100).round()}%',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 8,
              backgroundColor: AppColors.mint,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String hint;
  final bool filled;
  final VoidCallback onTap;
  const _InfoStatCard({
    required this.title,
    required this.value,
    required this.hint,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = filled
        ? AppColors.mintDeep.withValues(alpha: 0.55)
        : Colors.white;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_outward_rounded,
                  color: AppColors.primary,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              hint,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              const Divider(height: 1, indent: 56, endIndent: 16),
          ],
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _SettingTile({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: AppColors.primary, size: 18),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing:
          trailing ??
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}
