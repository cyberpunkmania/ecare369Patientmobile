import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/theme_config.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../../core/widgets/top_notification.dart';
import '../bloc/booking_cubit.dart';
import '../bloc/booking_state.dart';
import '../widgets/step_doctors.dart';
import '../widgets/step_calendar.dart';
import '../widgets/step_time_slots.dart';
import '../widgets/step_review.dart';
import '../widgets/step_payment.dart';
import '../widgets/step_success.dart';

/// 6-step appointment booking wizard.
///
/// Steps:
///   0 – Browse & pick a doctor
///   1 – Pick a date (week calendar)
///   2 – Pick a time slot (hold it)
///   3 – Review details
///   4 – Pay with M-Pesa
///   5 – Success
class BookingWizardPage extends StatefulWidget {
  const BookingWizardPage({super.key});

  @override
  State<BookingWizardPage> createState() => _BookingWizardPageState();
}

class _BookingWizardPageState extends State<BookingWizardPage> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    final cubit = context.read<BookingWizardCubit>();
    // Load doctors immediately (tenant-scoped via JWT) and load profile in
    // parallel so it's ready by the time the user reaches the review step.
    cubit.loadDoctors();
    cubit.loadPatientProfile();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  static const _stepLabels = [
    'Select Doctor',
    'Choose Date',
    'Pick Time',
    'Review',
    'Payment',
    'Confirmed',
  ];

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BookingWizardCubit, BookingWizardState>(
      listenWhen: (prev, curr) =>
          prev.currentStep != curr.currentStep ||
          prev.errorMessage != curr.errorMessage,
      listener: (context, state) {
        // Animate PageView to new step
        if (_pageController.hasClients &&
            _pageController.page?.round() != state.currentStep) {
          _pageController.animateToPage(
            state.currentStep,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
        // Show error banner
        if (state.errorMessage != null) {
          TopNotification.show(
            context,
            state.errorMessage!,
            type: NotificationType.error,
          );
          context.read<BookingWizardCubit>().clearError();
        }
      },
      builder: (context, state) {
        final isSuccess = state.currentStep == 5;

        return PopScope(
          canPop: state.currentStep == 0 || isSuccess,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && !isSuccess) {
              context.read<BookingWizardCubit>().goBack();
            }
          },
          child: Scaffold(
            appBar: isSuccess
                ? null
                : AppBar(
                    title: Text(_stepLabels[state.currentStep]),
                    leading: state.currentStep == 0
                        ? const BackButton()
                        : IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () =>
                                context.read<BookingWizardCubit>().goBack(),
                          ),
                  ),
            body: LoadingOverlay(
              isLoading: state.isLoading,
              message: _loadingHint(state),
              child: Column(
                children: [
                  // ── Step progress indicator ──
                  if (!isSuccess)
                    _StepProgressBar(
                      currentStep: state.currentStep,
                      labels: _stepLabels,
                    ),

                  // ── Step pages ──
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: const [
                        StepDoctors(),
                        StepCalendar(),
                        StepTimeSlots(),
                        StepReview(),
                        StepPayment(),
                        StepSuccess(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String? _loadingHint(BookingWizardState state) {
    if (!state.isLoading) return null;
    switch (state.currentStep) {
      case 0:
        return 'Loading doctors…';
      case 1:
        return 'Fetching schedule…';
      case 2:
        return 'Holding slot…';
      case 4:
        return 'Confirming booking…';
      default:
        return null;
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Step progress bar
// ─────────────────────────────────────────────────────────────

class _StepProgressBar extends StatelessWidget {
  final int currentStep;
  final List<String> labels;

  const _StepProgressBar({required this.currentStep, required this.labels});

  @override
  Widget build(BuildContext context) {
    // Show steps 0-3 only (not the success step)
    final stepsToShow = labels.length - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: List.generate(stepsToShow * 2 - 1, (index) {
          if (index.isOdd) {
            // Connector line
            final stepLeft = index ~/ 2;
            return Expanded(
              child: Container(
                height: 2,
                color: stepLeft < currentStep
                    ? AppColors.primary
                    : AppColors.textHint,
              ),
            );
          }
          final step = index ~/ 2;
          final isCompleted = step < currentStep;
          final isCurrent = step == currentStep;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: isCompleted
                    ? AppColors.primary
                    : isCurrent
                    ? AppColors.primaryLight
                    : AppColors.textHint,
                child: isCompleted
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : Text(
                        '${step + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isCurrent ? Colors.white : Colors.white70,
                        ),
                      ),
              ),
              const SizedBox(height: 4),
              Text(
                labels[step],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                  color: isCurrent
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
