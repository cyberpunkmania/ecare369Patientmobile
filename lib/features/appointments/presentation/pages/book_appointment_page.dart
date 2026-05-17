import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/theme_config.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../../core/widgets/top_notification.dart';
import '../bloc/appointment_bloc.dart';
import '../bloc/appointment_event.dart';
import '../bloc/appointment_state.dart';

class BookAppointmentPage extends StatefulWidget {
  const BookAppointmentPage({super.key});

  @override
  State<BookAppointmentPage> createState() => _BookAppointmentPageState();
}

class _BookAppointmentPageState extends State<BookAppointmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _doctorIdController = TextEditingController();
  final _reasonController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTimeSlot = '09:00 AM';
  String _selectedType = 'in-person';

  final List<String> _timeSlots = [
    '09:00 AM',
    '09:30 AM',
    '10:00 AM',
    '10:30 AM',
    '11:00 AM',
    '11:30 AM',
    '02:00 PM',
    '02:30 PM',
    '03:00 PM',
    '03:30 PM',
    '04:00 PM',
    '04:30 PM',
  ];

  final List<String> _types = ['in-person', 'video', 'phone'];

  @override
  void dispose() {
    _doctorIdController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      TopNotification.show(
        context,
        'Please fill in all fields',
        type: NotificationType.warning,
      );
      return;
    }

    context.read<AppointmentBloc>().add(
      AppointmentBooked(
        doctorId: _doctorIdController.text.trim(),
        date: _selectedDate,
        timeSlot: _selectedTimeSlot,
        type: _selectedType,
        reason: _reasonController.text.trim().isEmpty
            ? null
            : _reasonController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppointmentBloc, AppointmentState>(
      listener: (context, state) {
        if (state is AppointmentBookedSuccess) {
          TopNotification.show(
            context,
            'Appointment booked successfully!',
            type: NotificationType.success,
          );
          Navigator.of(context).pop();
        }
        if (state is AppointmentError) {
          TopNotification.show(
            context,
            state.message,
            type: NotificationType.error,
          );
        }
      },
      child: BlocBuilder<AppointmentBloc, AppointmentState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(title: const Text('Book Appointment')),
            body: LoadingOverlay(
              isLoading: state is AppointmentLoading,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Doctor ID
                      TextFormField(
                        controller: _doctorIdController,
                        decoration: const InputDecoration(
                          labelText: 'Doctor ID',
                          prefixIcon: Icon(Icons.person_search),
                          hintText: 'Enter doctor ID or search',
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Date Picker
                      ListTile(
                        tileColor: Theme.of(
                          context,
                        ).inputDecorationTheme.fillColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: AppColors.textHint),
                        ),
                        leading: const Icon(Icons.calendar_today),
                        title: const Text('Appointment Date'),
                        subtitle: Text(
                          DateFormat('EEE, MMM d, yyyy').format(_selectedDate),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _pickDate,
                      ),
                      const SizedBox(height: 16),

                      // Time Slot
                      DropdownButtonFormField<String>(
                        value: _selectedTimeSlot,
                        decoration: const InputDecoration(
                          labelText: 'Time Slot',
                          prefixIcon: Icon(Icons.access_time),
                        ),
                        items: _timeSlots
                            .map(
                              (t) => DropdownMenuItem(value: t, child: Text(t)),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedTimeSlot = v!),
                      ),
                      const SizedBox(height: 16),

                      // Type
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Appointment Type',
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: _types
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(
                                  t[0].toUpperCase() + t.substring(1),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _selectedType = v!),
                      ),
                      const SizedBox(height: 16),

                      // Reason
                      TextFormField(
                        controller: _reasonController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Reason (optional)',
                          prefixIcon: Icon(Icons.note),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: _submit,
                        child: const Text(
                          'Book Appointment',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
