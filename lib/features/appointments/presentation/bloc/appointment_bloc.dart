import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_appointments_usecase.dart';
import '../../domain/usecases/book_appointment_usecase.dart';
import '../../domain/usecases/cancel_appointment_usecase.dart';
import 'appointment_event.dart';
import 'appointment_state.dart';

class AppointmentBloc extends Bloc<AppointmentEvent, AppointmentState> {
  final GetAppointmentsUseCase _getAppointments;
  final BookAppointmentUseCase _bookAppointment;
  final CancelAppointmentUseCase _cancelAppointment;

  AppointmentBloc({
    required GetAppointmentsUseCase getAppointments,
    required BookAppointmentUseCase bookAppointment,
    required CancelAppointmentUseCase cancelAppointment,
  }) : _getAppointments = getAppointments,
       _bookAppointment = bookAppointment,
       _cancelAppointment = cancelAppointment,
       super(AppointmentInitial()) {
    on<AppointmentsLoaded>(_onLoaded);
    on<AppointmentBooked>(_onBooked);
    on<AppointmentCancelled>(_onCancelled);
  }

  Future<void> _onLoaded(
    AppointmentsLoaded event,
    Emitter<AppointmentState> emit,
  ) async {
    emit(AppointmentLoading());
    final result = await _getAppointments();
    result.fold(
      (failure) => emit(AppointmentError(message: failure.message)),
      (appointments) => emit(AppointmentListLoaded(appointments: appointments)),
    );
  }

  Future<void> _onBooked(
    AppointmentBooked event,
    Emitter<AppointmentState> emit,
  ) async {
    emit(AppointmentLoading());
    final result = await _bookAppointment(
      doctorId: event.doctorId,
      date: event.date,
      timeSlot: event.timeSlot,
      type: event.type,
      reason: event.reason,
    );
    result.fold((failure) => emit(AppointmentError(message: failure.message)), (
      appointment,
    ) {
      emit(AppointmentBookedSuccess(appointment: appointment));
      // Refresh the list.
      add(AppointmentsLoaded());
    });
  }

  Future<void> _onCancelled(
    AppointmentCancelled event,
    Emitter<AppointmentState> emit,
  ) async {
    emit(AppointmentLoading());
    final result = await _cancelAppointment(event.id, reason: event.reason);
    result.fold((failure) => emit(AppointmentError(message: failure.message)), (
      _,
    ) {
      emit(AppointmentCancelledSuccess());
      add(AppointmentsLoaded());
    });
  }
}
