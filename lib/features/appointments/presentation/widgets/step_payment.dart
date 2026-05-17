import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/theme_config.dart';
import '../bloc/booking_cubit.dart';
import '../bloc/booking_state.dart';

/// Step 4 – Initiate M-Pesa STK push and confirm booking.
class StepPayment extends StatefulWidget {
  const StepPayment({super.key});

  @override
  State<StepPayment> createState() => _StepPaymentState();
}

class _StepPaymentState extends State<StepPayment> {
  final _phoneController = TextEditingController();
  bool _phoneInitialised = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BookingWizardCubit, BookingWizardState>(
      listenWhen: (prev, curr) =>
          prev.paymentMessage != curr.paymentMessage &&
          curr.paymentMessage != null,
      listener: (context, state) {
        if (state.paymentMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.paymentMessage!),
              backgroundColor: AppColors.success,
            ),
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<BookingWizardCubit>();
        final doctor = state.selectedDoctor;
        final slot = state.selectedSlot;

        // One-time prefill from cubit state (driven by patient profile).
        if (!_phoneInitialised && state.paymentPhoneNumber.isNotEmpty) {
          _phoneController.text = state.paymentPhoneNumber;
          _phoneInitialised = true;
        }

        if (doctor == null || slot == null) {
          return const Center(child: Text('Missing booking details'));
        }

        final feeLabel = doctor.consultationFee > 0
            ? '${doctor.currency} ${doctor.consultationFee.toStringAsFixed(0)}'
            : '${doctor.currency} 1 (minimum)';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Brief appointment summary ──
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor.doctorName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${slot.date}  •  ${_fmtTime(slot.startTime)} – ${_fmtTime(slot.endTime)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Consultation fee: $feeLabel',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── M-Pesa payment ──
              Card(
                color: AppColors.success.withValues(alpha: 0.06),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.phone_android,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Pay with M-Pesa',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You will receive an STK push on this number to pay $feeLabel.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'M-Pesa phone number',
                          hintText: '0712 345 678',
                          prefixIcon: Icon(Icons.phone),
                        ),
                        onChanged: cubit.setPaymentPhoneNumber,
                      ),
                      if (state.paymentResult != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'STK push sent — check your phone to complete '
                          'payment, then this booking will be confirmed.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.success),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Pay & Confirm button ──
              ElevatedButton.icon(
                onPressed: (state.isLoading || state.isInitiatingPayment)
                    ? null
                    : cubit.payAndConfirmBooking,
                icon: state.isInitiatingPayment
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  state.isInitiatingPayment
                      ? 'Sending STK push…'
                      : (state.isLoading
                            ? 'Confirming…'
                            : 'Pay with M-Pesa & Confirm'),
                ),
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
