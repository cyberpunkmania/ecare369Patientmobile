import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/theme_config.dart';
import '../../domain/entities/patient_profile_entity.dart';

/// Bottom sheet used for both adding (blank) and editing (pre-populated)
/// an insurance policy on a patient profile.
///
/// Pass [initialInsurance] to open in edit mode; leave it null for add mode.
class InsuranceAddSheet extends StatefulWidget {
  /// Called when saving a NEW insurance. Required when [initialInsurance] is null.
  final Future<void> Function({
    required String providerId,
    String? schemeId,
    required String policyNumber,
    String? memberNumber,
    DateTime? validFrom,
    DateTime? validTo,
    bool isPrimary,
  })?
  onAdd;

  /// Called when saving an EXISTING insurance. Required when [initialInsurance]
  /// is not null.
  final Future<void> Function({
    required String insuranceId,
    required String providerName,
    required String policyNumber,
    String? memberNumber,
    DateTime? validFrom,
    DateTime? validTo,
    bool isPrimary,
  })?
  onUpdate;

  /// When non-null, the sheet opens in edit mode with fields pre-populated.
  final InsurancePolicyEntity? initialInsurance;

  const InsuranceAddSheet({
    super.key,
    this.onAdd,
    this.onUpdate,
    this.initialInsurance,
  }) : assert(
         initialInsurance == null ? onAdd != null : onUpdate != null,
         'Provide onAdd for add-mode or onUpdate for edit-mode.',
       );

  bool get isEditing => initialInsurance != null;

  @override
  State<InsuranceAddSheet> createState() => _InsuranceAddSheetState();
}

class _InsuranceAddSheetState extends State<InsuranceAddSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _providerId;
  late final TextEditingController _schemeId;
  late final TextEditingController _policy;
  late final TextEditingController _member;
  DateTime? _from;
  DateTime? _to;
  bool _primary = false;

  @override
  void initState() {
    super.initState();
    final ins = widget.initialInsurance;
    _providerId = TextEditingController(text: ins?.providerName ?? '');
    _schemeId = TextEditingController(text: ins?.schemeName ?? '');
    _policy = TextEditingController(text: ins?.policyNumber ?? '');
    _member = TextEditingController(text: ins?.memberNumber ?? '');
    _from = ins?.validFrom;
    _to = ins?.validTo;
    _primary = ins?.isPrimary ?? false;
  }

  @override
  void dispose() {
    _providerId.dispose();
    _schemeId.dispose();
    _policy.dispose();
    _member.dispose();
    super.dispose();
  }

  Future<void> _pick({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _from : _to) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _from = picked;
        } else {
          _to = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (widget.isEditing) {
      await widget.onUpdate!(
        insuranceId: widget.initialInsurance!.id,
        providerName: _providerId.text.trim(),
        policyNumber: _policy.text.trim(),
        memberNumber: _member.text.trim().isEmpty ? null : _member.text.trim(),
        validFrom: _from,
        validTo: _to,
        isPrimary: _primary,
      );
    } else {
      await widget.onAdd!(
        providerId: _providerId.text.trim(),
        schemeId: _schemeId.text.trim().isEmpty ? null : _schemeId.text.trim(),
        policyNumber: _policy.text.trim(),
        memberNumber: _member.text.trim().isEmpty ? null : _member.text.trim(),
        validFrom: _from,
        validTo: _to,
        isPrimary: _primary,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    final isEditing = widget.isEditing;
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
          child: Form(
            key: _formKey,
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
                  Text(
                    isEditing ? 'Edit insurance' : 'Add insurance',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _providerId,
                    decoration: _decoration(label: 'Insurance Company'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  if (!isEditing) ...[
                    TextFormField(
                      controller: _schemeId,
                      decoration: _decoration(
                        label: 'Scheme ID (optional, UUID)',
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: _policy,
                    decoration: _decoration(label: 'Policy number'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _member,
                    decoration: _decoration(label: 'Member number (optional)'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _dateField('Valid from', _from, true)),
                      const SizedBox(width: 12),
                      Expanded(child: _dateField('Valid to', _to, false)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.primary,
                    title: const Text(
                      'Primary policy',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    value: _primary,
                    onChanged: (v) => setState(() => _primary = v),
                  ),
                  const SizedBox(height: 12),
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
                      child: Text(
                        isEditing ? 'Save changes' : 'Add',
                        style: const TextStyle(
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
      ),
    );
  }

  Widget _dateField(String label, DateTime? value, bool isFrom) {
    return InkWell(
      onTap: () => _pick(isFrom: isFrom),
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: _decoration(label: label),
        child: Text(
          value == null
              ? 'Select date'
              : DateFormat('d MMM yyyy').format(value),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
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
