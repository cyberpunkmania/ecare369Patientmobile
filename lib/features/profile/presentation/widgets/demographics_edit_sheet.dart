import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/theme_config.dart';
import '../../domain/entities/patient_profile_entity.dart';

/// Bottom-sheet editor for the demographics section of a patient profile.
class DemographicsEditSheet extends StatefulWidget {
  final PatientProfileEntity initial;
  final Future<void> Function({
    DateTime? dateOfBirth,
    String? gender,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? country,
    String? postalCode,
  })
  onSave;

  const DemographicsEditSheet({
    super.key,
    required this.initial,
    required this.onSave,
  });

  @override
  State<DemographicsEditSheet> createState() => _DemographicsEditSheetState();
}

class _DemographicsEditSheetState extends State<DemographicsEditSheet> {
  late final TextEditingController _addressLine1;
  late final TextEditingController _addressLine2;
  late final TextEditingController _city;
  late final TextEditingController _country;
  late final TextEditingController _postal;
  DateTime? _dob;
  String? _gender;

  static const _genders = ['Male', 'Female', 'Other', 'Prefer not to say'];

  @override
  void initState() {
    super.initState();
    _addressLine1 = TextEditingController(
      text: widget.initial.addressLine1 ?? '',
    );
    _addressLine2 = TextEditingController(
      text: widget.initial.addressLine2 ?? '',
    );
    _city = TextEditingController(text: widget.initial.city ?? '');
    _country = TextEditingController(text: widget.initial.country ?? '');
    _postal = TextEditingController(text: widget.initial.postalCode ?? '');
    _dob = widget.initial.dateOfBirth;
    _gender = widget.initial.gender;
  }

  @override
  void dispose() {
    _addressLine1.dispose();
    _addressLine2.dispose();
    _city.dispose();
    _country.dispose();
    _postal.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(DateTime.now().year - 25),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _dob = picked);
    }
  }

  Future<void> _save() async {
    await widget.onSave(
      dateOfBirth: _dob,
      gender: _gender,
      addressLine1: _addressLine1.text.trim().isEmpty
          ? null
          : _addressLine1.text.trim(),
      addressLine2: _addressLine2.text.trim().isEmpty
          ? null
          : _addressLine2.text.trim(),
      city: _city.text.trim().isEmpty ? null : _city.text.trim(),
      country: _country.text.trim().isEmpty ? null : _country.text.trim(),
      postalCode: _postal.text.trim().isEmpty ? null : _postal.text.trim(),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textHint.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Edit demographics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _pickDob,
                  borderRadius: BorderRadius.circular(14),
                  child: InputDecorator(
                    decoration: _decoration(label: 'Date of birth'),
                    child: Text(
                      _dob == null
                          ? 'Select date'
                          : DateFormat('d MMM yyyy').format(_dob!),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: _decoration(label: 'Gender'),
                  items: _genders
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) => setState(() => _gender = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _addressLine1,
                  decoration: _decoration(label: 'Address line 1'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _addressLine2,
                  decoration: _decoration(label: 'Address line 2 (optional)'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _city,
                        decoration: _decoration(label: 'City'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _postal,
                        decoration: _decoration(label: 'Postal'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _country,
                  decoration: _decoration(label: 'Country'),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _save,
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration({required String label}) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.mint.withValues(alpha: 0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }
}
