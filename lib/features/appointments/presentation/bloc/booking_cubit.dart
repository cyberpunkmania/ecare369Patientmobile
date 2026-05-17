import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../data/models/appointment_slot_dto.dart';
import '../../data/models/confirm_booking_request.dart';
import '../../data/models/doctor_availability_dto.dart';
import '../../domain/repositories/booking_repository.dart';
import 'booking_state.dart';

class BookingWizardCubit extends Cubit<BookingWizardState> {
  final BookingRepository _repository;

  /// Auth context — set once on creation.
  final String patientId;
  final String branchId;
  final String tenantId;
  final String patientName;

  Timer? _holdTimer;

  BookingWizardCubit({
    required BookingRepository repository,
    required this.patientId,
    required this.branchId,
    required this.tenantId,
    required this.patientName,
  }) : _repository = repository,
       super(const BookingWizardState());

  // ────────────────────────────────────────────────────────────
  // Pre-step: load patient profile
  // ────────────────────────────────────────────────────────────

  Future<void> loadPatientProfile() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    final result = await _repository.getPatientProfile(patientId);
    result.fold(
      (f) => emit(state.copyWith(isLoading: false, errorMessage: f.message)),
      (profile) => emit(
        state.copyWith(
          isLoading: false,
          patientProfile: profile,
          // Pre-fill the M-Pesa STK number with the patient's profile phone
          // when one isn't already set.
          paymentPhoneNumber: state.paymentPhoneNumber.isEmpty
              ? (profile.phoneNumber)
              : state.paymentPhoneNumber,
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // Step 1: Browse available doctors
  // ────────────────────────────────────────────────────────────

  /// Load all active doctors in the patient's tenant.
  ///
  /// Mirrors the web frontend: calls `/api/doctors?status=Active` and
  /// shows every approved doctor regardless of branch or specific date.
  /// Schedule resolution is deferred to [selectDoctor].
  Future<void> loadDoctors({String? specialty, bool? onlineOnly}) async {
    final online = onlineOnly ?? state.onlineOnly;
    emit(
      state.copyWith(
        isLoading: true,
        clearError: true,
        specialtyFilter: specialty,
        clearSpecialtyFilter: specialty == null,
        onlineOnly: online,
      ),
    );
    final result = await _repository.getActiveDoctors(specialty: specialty);
    result.fold(
      (f) => emit(state.copyWith(isLoading: false, errorMessage: f.message)),
      (doctors) => emit(state.copyWith(isLoading: false, doctors: doctors)),
    );
  }

  Future<void> selectDoctor(DoctorAvailabilityDto doctor) async {
    // If schedule is already known (legacy path), proceed immediately.
    if (doctor.scheduleId.isNotEmpty) {
      emit(
        state.copyWith(
          selectedDoctor: doctor,
          currentStep: 1,
          weekSlots: const [],
          clearSelectedDate: true,
          daySlots: const [],
          clearSelectedSlot: true,
          clearSlotHold: true,
        ),
      );
      await _loadWeekSlots();
      return;
    }

    // Resolve scheduleId for this doctor at their branch.
    if (doctor.branchId.isEmpty) {
      emit(
        state.copyWith(
          errorMessage:
              'This doctor is not assigned to a branch yet. Please choose another doctor.',
        ),
      );
      return;
    }

    emit(state.copyWith(isLoading: true, clearError: true));
    final scheduleResult = await _repository.resolveScheduleId(
      doctorId: doctor.doctorId,
      branchId: doctor.branchId,
    );
    await scheduleResult.fold(
      (f) async =>
          emit(state.copyWith(isLoading: false, errorMessage: f.message)),
      (scheduleId) async {
        final enriched = doctor.copyWith(scheduleId: scheduleId);
        emit(
          state.copyWith(
            isLoading: false,
            selectedDoctor: enriched,
            currentStep: 1,
            weekSlots: const [],
            clearSelectedDate: true,
            daySlots: const [],
            clearSelectedSlot: true,
            clearSlotHold: true,
          ),
        );
        await _loadWeekSlots();
      },
    );
  }

  // ────────────────────────────────────────────────────────────
  // Step 2: Pick a date (week calendar)
  // ────────────────────────────────────────────────────────────

  Future<void> _loadWeekSlots({DateTime? weekStart}) async {
    final doctor = state.selectedDoctor;
    if (doctor == null) return;

    final start = weekStart ?? _mondayOfThisWeek();
    final end = start.add(const Duration(days: 6));
    final fmt = DateFormat('yyyy-MM-dd');

    emit(state.copyWith(isLoading: true, clearError: true));
    final result = await _repository.getSlotRange(
      scheduleId: doctor.scheduleId,
      from: fmt.format(start),
      to: fmt.format(end),
    );
    result.fold(
      (f) => emit(state.copyWith(isLoading: false, errorMessage: f.message)),
      (slots) => emit(state.copyWith(isLoading: false, weekSlots: slots)),
    );
  }

  void loadPreviousWeek() {
    if (state.weekSlots.isEmpty) return;
    final first = DateTime.parse(state.weekSlots.first.date);
    _loadWeekSlots(weekStart: first.subtract(const Duration(days: 7)));
  }

  void loadNextWeek() {
    if (state.weekSlots.isEmpty) return;
    final first = DateTime.parse(state.weekSlots.first.date);
    _loadWeekSlots(weekStart: first.add(const Duration(days: 7)));
  }

  Future<void> selectDate(String date) async {
    final doctor = state.selectedDoctor;
    if (doctor == null) return;

    emit(
      state.copyWith(
        selectedDate: date,
        isLoading: true,
        clearError: true,
        daySlots: const [],
        clearSelectedSlot: true,
        clearSlotHold: true,
        currentStep: 2,
      ),
    );
    final result = await _repository.getSlotsForDate(
      scheduleId: doctor.scheduleId,
      date: date,
    );
    result.fold(
      (f) => emit(state.copyWith(isLoading: false, errorMessage: f.message)),
      (slotsDto) {
        final now = DateTime.now();
        // Keep slots that are exposed to online booking (Available + OnHold)
        // so the UI can display held slots as disabled. Drop past slots when
        // the selected date is today, and drop slots that aren't available
        // for online booking at all.
        final visible = slotsDto.availableSlots.where((s) {
          if (!s.allowOnlineBooking) return false;
          if (s.status != SlotStatus.Available &&
              s.status != SlotStatus.OnHold) {
            return false;
          }
          if (s.isPast(now)) return false;
          return true;
        }).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));
        emit(state.copyWith(isLoading: false, daySlots: visible));
      },
    );
  }

  // ────────────────────────────────────────────────────────────
  // Step 3: Pick a time slot + hold it
  // ────────────────────────────────────────────────────────────

  Future<void> selectSlot(AppointmentSlotDto slot) async {
    final doctor = state.selectedDoctor;
    if (doctor == null) return;

    // Guard against tapping a held / past slot.
    if (!slot.isBookableNow(DateTime.now())) {
      final reason = slot.status == SlotStatus.OnHold
          ? 'This slot is currently held by another patient. Please choose a different time.'
          : 'This time has already passed. Please choose a future slot.';
      emit(state.copyWith(errorMessage: reason));
      return;
    }

    emit(state.copyWith(selectedSlot: slot, isLoading: true, clearError: true));
    final result = await _repository.holdSlot(
      scheduleId: doctor.scheduleId,
      slotId: slot.id,
      patientId: patientId,
      slotDate: slot.date,
    );
    result.fold(
      (f) => emit(
        state.copyWith(
          isLoading: false,
          errorMessage: f.message,
          clearSelectedSlot: true,
        ),
      ),
      (hold) {
        final seconds = _secondsUntil(hold.holdExpiresAt);
        emit(
          state.copyWith(
            isLoading: false,
            slotHold: hold,
            holdSecondsRemaining: seconds,
            currentStep: 3,
          ),
        );
        _startHoldCountdown();
      },
    );
  }

  // ────────────────────────────────────────────────────────────
  // Step 4: Review & confirm
  // ────────────────────────────────────────────────────────────

  void setReasonForVisit(String reason) {
    emit(state.copyWith(reasonForVisit: reason));
  }

  /// Advances from the review step (3) to the payment step (4).
  void proceedToPayment() {
    emit(state.copyWith(currentStep: 4));
  }

  /// Updates the phone number that will receive the M-Pesa STK push prompt.
  void setPaymentPhoneNumber(String phone) {
    emit(state.copyWith(paymentPhoneNumber: phone));
  }

  /// Normalises a Kenyan phone number to the `2547XXXXXXXX` / `2541XXXXXXXX`
  /// format Daraja expects. Returns `null` if the input doesn't look like a
  /// valid Kenyan mobile number.
  String? _normalisePhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    String normalized = digits;
    if (normalized.startsWith('0') && normalized.length == 10) {
      normalized = '254${normalized.substring(1)}';
    } else if (normalized.startsWith('7') || normalized.startsWith('1')) {
      if (normalized.length == 9) normalized = '254$normalized';
    }
    if (normalized.length != 12 || !normalized.startsWith('254')) return null;
    return normalized;
  }

  /// Initiates an M-Pesa STK push for the consultation fee, then — on
  /// success — immediately confirms the booking. The patient sees a prompt
  /// on their phone to enter the M-Pesa PIN.
  Future<void> payAndConfirmBooking() async {
    final doctor = state.selectedDoctor;
    final slot = state.selectedSlot;
    final hold = state.slotHold;
    if (doctor == null || slot == null || hold == null) return;

    final normalisedPhone = _normalisePhone(state.paymentPhoneNumber);
    if (normalisedPhone == null) {
      emit(
        state.copyWith(
          errorMessage: 'Enter a valid Kenyan phone number (e.g. 0712345678).',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        isInitiatingPayment: true,
        clearError: true,
        clearPaymentMessage: true,
      ),
    );

    final paymentResult = await _repository.initiateMpesaStk(
      branchId: branchId.isNotEmpty ? branchId : doctor.branchId,
      phoneNumber: normalisedPhone,
      // Daraja rejects 0-amount STK pushes. Fall back to KES 1 when the
      // doctor's consultation fee isn't published so we can still smoke-test
      // the booking flow end-to-end.
      amount: doctor.consultationFee > 0 ? doctor.consultationFee : 1,
      slotId: slot.id,
      patientId: patientId,
    );

    final shouldConfirm = await paymentResult.fold(
      (f) async {
        emit(
          state.copyWith(isInitiatingPayment: false, errorMessage: f.message),
        );
        return false;
      },
      (res) async {
        emit(
          state.copyWith(
            isInitiatingPayment: false,
            paymentResult: res,
            paymentMessage:
                res.customerMessage ??
                'STK push sent. Check your phone to complete payment.',
          ),
        );
        return true;
      },
    );

    if (shouldConfirm) {
      await confirmBooking();
    }
  }

  Future<void> confirmBooking() async {
    final doctor = state.selectedDoctor;
    final slot = state.selectedSlot;
    final hold = state.slotHold;
    final profile = state.patientProfile;
    if (doctor == null || slot == null || hold == null) return;

    emit(state.copyWith(isLoading: true, clearError: true));

    final request = ConfirmBookingRequest(
      slotId: slot.id,
      scheduleId: doctor.scheduleId,
      appointmentDate: slot.date,
      startTime: slot.startTime,
      endTime: slot.endTime,
      tenantId: tenantId,
      // Use the doctor's branch when the patient is not bound to one.
      branchId: branchId.isNotEmpty ? branchId : doctor.branchId,
      patientId: patientId,
      patientName: patientName,
      outpatientNumber: profile?.outpatientNumber ?? '',
      patientPhone: profile?.phoneNumber,
      doctorId: doctor.doctorId,
      doctorName: doctor.doctorName,
      doctorSpecialization: doctor.specialization,
      consultationFee: doctor.consultationFee,
      currency: doctor.currency,
      reasonForVisit: state.reasonForVisit.isEmpty
          ? null
          : state.reasonForVisit,
      appointmentTypeLabel: 'Outpatient',
    );

    final result = await _repository.confirmBooking(request);
    result.fold(
      (f) => emit(state.copyWith(isLoading: false, errorMessage: f.message)),
      (appointmentId) {
        _cancelHoldTimer();
        emit(
          state.copyWith(
            isLoading: false,
            bookingConfirmedId: appointmentId,
            currentStep: 5,
          ),
        );
      },
    );
  }

  // ────────────────────────────────────────────────────────────
  // Navigation helpers
  // ────────────────────────────────────────────────────────────

  Future<void> goBack() async {
    if (state.currentStep == 0) return;

    // Going from payment step (4) back to review (3) — keep the slot hold.
    // Going from review step (3) or earlier back — release the hold.
    if (state.slotHold != null &&
        state.selectedDoctor != null &&
        state.currentStep <= 3) {
      _cancelHoldTimer();
      await _repository.releaseSlot(
        scheduleId: state.selectedDoctor!.scheduleId,
        slotId: state.slotHold!.slotId,
        patientId: patientId,
      );
      emit(
        state.copyWith(
          clearSlotHold: true,
          clearSelectedSlot: true,
          holdSecondsRemaining: 0,
          currentStep: state.currentStep - 1,
        ),
      );
    } else {
      emit(state.copyWith(currentStep: state.currentStep - 1));
    }
  }

  void resetWizard() {
    _cancelHoldTimer();
    emit(const BookingWizardState());
  }

  void clearError() {
    emit(state.copyWith(clearError: true));
  }

  // ────────────────────────────────────────────────────────────
  // Hold countdown timer
  // ────────────────────────────────────────────────────────────

  void _startHoldCountdown() {
    _cancelHoldTimer();
    _holdTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = state.holdSecondsRemaining - 1;
      if (remaining <= 0) {
        _cancelHoldTimer();
        // Slot expired → go back to time slot selection
        emit(
          state.copyWith(
            holdSecondsRemaining: 0,
            clearSlotHold: true,
            clearSelectedSlot: true,
            currentStep: 2,
            errorMessage: 'Slot hold expired. Please select another time.',
          ),
        );
      } else {
        emit(state.copyWith(holdSecondsRemaining: remaining));
      }
    });
  }

  void _cancelHoldTimer() {
    _holdTimer?.cancel();
    _holdTimer = null;
  }

  int _secondsUntil(String isoTimestamp) {
    try {
      final expiry = DateTime.parse(isoTimestamp);
      final diff = expiry.difference(DateTime.now()).inSeconds;
      return diff > 0 ? diff : 0;
    } catch (_) {
      return 600; // fallback 10 min
    }
  }

  DateTime _mondayOfThisWeek() {
    final now = DateTime.now();
    return now.subtract(Duration(days: now.weekday - 1));
  }

  /// Release held slot on dispose (wizard exit).
  Future<void> releaseHeldSlot() async {
    if (state.slotHold != null && state.selectedDoctor != null) {
      _cancelHoldTimer();
      await _repository.releaseSlot(
        scheduleId: state.selectedDoctor!.scheduleId,
        slotId: state.slotHold!.slotId,
        patientId: patientId,
      );
    }
  }

  @override
  Future<void> close() async {
    await releaseHeldSlot();
    _cancelHoldTimer();
    return super.close();
  }
}
