import 'package:equatable/equatable.dart';

import '../../data/models/appointment_slot_dto.dart';
import '../../data/models/doctor_availability_dto.dart';
import '../../data/models/doctor_available_slots_dto.dart';
import '../../data/models/mpesa_initiate_result.dart';
import '../../data/models/patient_profile_dto.dart';
import '../../data/models/slot_hold_dto.dart';

class BookingWizardState extends Equatable {
  /// Current wizard step (0 = doctors, 1 = date, 2 = time, 3 = review, 4 = payment, 5 = success).
  final int currentStep;
  final bool isLoading;
  final String? errorMessage;

  // Pre-step: patient profile
  final PatientProfileDto? patientProfile;

  // Step 1: Doctor selection
  final List<DoctorAvailabilityDto> doctors;
  final DoctorAvailabilityDto? selectedDoctor;
  final String? specialtyFilter;
  final bool onlineOnly;

  // Step 2: Date selection (week view)
  final List<DoctorAvailableSlotsDto> weekSlots;
  final String? selectedDate;

  // Step 3: Time slot selection
  final List<AppointmentSlotDto> daySlots;
  final AppointmentSlotDto? selectedSlot;

  // Step 3b: Slot hold
  final SlotHoldDto? slotHold;
  final int holdSecondsRemaining;

  // Step 4: Review
  final String reasonForVisit;

  // Step 4b: Payment (M-Pesa STK push) — runs before confirm
  /// Phone number the STK push will be sent to. Defaults to the patient's
  /// profile phone but can be overridden in the review step.
  final String paymentPhoneNumber;
  final bool isInitiatingPayment;
  final MpesaInitiateResult? paymentResult;
  final String? paymentMessage;

  // Step 5: Success
  final String? bookingConfirmedId;

  const BookingWizardState({
    this.currentStep = 0,
    this.isLoading = false,
    this.errorMessage,
    this.patientProfile,
    this.doctors = const [],
    this.selectedDoctor,
    this.specialtyFilter,
    this.onlineOnly = true,
    this.weekSlots = const [],
    this.selectedDate,
    this.daySlots = const [],
    this.selectedSlot,
    this.slotHold,
    this.holdSecondsRemaining = 0,
    this.reasonForVisit = '',
    this.paymentPhoneNumber = '',
    this.isInitiatingPayment = false,
    this.paymentResult,
    this.paymentMessage,
    this.bookingConfirmedId,
  });

  BookingWizardState copyWith({
    int? currentStep,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    PatientProfileDto? patientProfile,
    List<DoctorAvailabilityDto>? doctors,
    DoctorAvailabilityDto? selectedDoctor,
    bool clearSelectedDoctor = false,
    String? specialtyFilter,
    bool clearSpecialtyFilter = false,
    bool? onlineOnly,
    List<DoctorAvailableSlotsDto>? weekSlots,
    String? selectedDate,
    bool clearSelectedDate = false,
    List<AppointmentSlotDto>? daySlots,
    AppointmentSlotDto? selectedSlot,
    bool clearSelectedSlot = false,
    SlotHoldDto? slotHold,
    bool clearSlotHold = false,
    int? holdSecondsRemaining,
    String? reasonForVisit,
    String? paymentPhoneNumber,
    bool? isInitiatingPayment,
    MpesaInitiateResult? paymentResult,
    bool clearPaymentResult = false,
    String? paymentMessage,
    bool clearPaymentMessage = false,
    String? bookingConfirmedId,
  }) {
    return BookingWizardState(
      currentStep: currentStep ?? this.currentStep,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      patientProfile: patientProfile ?? this.patientProfile,
      doctors: doctors ?? this.doctors,
      selectedDoctor: clearSelectedDoctor
          ? null
          : (selectedDoctor ?? this.selectedDoctor),
      specialtyFilter: clearSpecialtyFilter
          ? null
          : (specialtyFilter ?? this.specialtyFilter),
      onlineOnly: onlineOnly ?? this.onlineOnly,
      weekSlots: weekSlots ?? this.weekSlots,
      selectedDate: clearSelectedDate
          ? null
          : (selectedDate ?? this.selectedDate),
      daySlots: daySlots ?? this.daySlots,
      selectedSlot: clearSelectedSlot
          ? null
          : (selectedSlot ?? this.selectedSlot),
      slotHold: clearSlotHold ? null : (slotHold ?? this.slotHold),
      holdSecondsRemaining: holdSecondsRemaining ?? this.holdSecondsRemaining,
      reasonForVisit: reasonForVisit ?? this.reasonForVisit,
      paymentPhoneNumber: paymentPhoneNumber ?? this.paymentPhoneNumber,
      isInitiatingPayment: isInitiatingPayment ?? this.isInitiatingPayment,
      paymentResult: clearPaymentResult
          ? null
          : (paymentResult ?? this.paymentResult),
      paymentMessage: clearPaymentMessage
          ? null
          : (paymentMessage ?? this.paymentMessage),
      bookingConfirmedId: bookingConfirmedId ?? this.bookingConfirmedId,
    );
  }

  @override
  List<Object?> get props => [
    currentStep,
    isLoading,
    errorMessage,
    patientProfile,
    doctors,
    selectedDoctor,
    specialtyFilter,
    onlineOnly,
    weekSlots,
    selectedDate,
    daySlots,
    selectedSlot,
    slotHold,
    holdSecondsRemaining,
    reasonForVisit,
    paymentPhoneNumber,
    isInitiatingPayment,
    paymentResult,
    paymentMessage,
    bookingConfirmedId,
  ];
}
