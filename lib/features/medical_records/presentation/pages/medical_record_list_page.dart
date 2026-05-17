import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/theme_config.dart';
import '../../domain/entities/medical_record_entity.dart';
import 'medical_record_detail_page.dart';

// ─────────────────────────────────────────────────────────────
// Static mock medical records (replace with real bloc-driven data later)
// ─────────────────────────────────────────────────────────────

final List<MedicalRecordEntity> _mockRecords = [
  MedicalRecordEntity(
    id: '1',
    title: 'Complete Blood Count (CBC)',
    type: 'lab_result',
    description: 'Routine blood work — all values within normal range.',
    doctorName: 'Dr. Sarah Kimani',
    date: DateTime.now().subtract(const Duration(days: 3)),
    details: {
      'Hemoglobin': '14.2 g/dL',
      'WBC': '6,800 /μL',
      'Platelets': '245,000 /μL',
      'RBC': '4.9 M/μL',
    },
  ),
  MedicalRecordEntity(
    id: '2',
    title: 'Amoxicillin 500 mg',
    type: 'prescription',
    description:
        'For upper respiratory tract infection. Take 3× daily for 7 days.',
    doctorName: 'Dr. James Odhiambo',
    date: DateTime.now().subtract(const Duration(days: 7)),
    details: {
      'Dosage': '500 mg',
      'Frequency': '3 times daily',
      'Duration': '7 days',
      'Refills': '0',
    },
  ),
  MedicalRecordEntity(
    id: '3',
    title: 'Hypertension – Stage 1',
    type: 'diagnosis',
    description:
        'Blood pressure consistently elevated at 140/90 mmHg. Lifestyle modifications advised.',
    doctorName: 'Dr. Grace Mwangi',
    date: DateTime.now().subtract(const Duration(days: 14)),
    details: {
      'Systolic': '140 mmHg',
      'Diastolic': '90 mmHg',
      'Risk Level': 'Moderate',
      'Follow-up': '4 weeks',
    },
  ),
  MedicalRecordEntity(
    id: '4',
    title: 'Annual Check-up Summary',
    type: 'visit_summary',
    description:
        'Comprehensive annual physical examination. Patient in good overall health.',
    doctorName: 'Dr. Sarah Kimani',
    date: DateTime.now().subtract(const Duration(days: 30)),
    details: {
      'Weight': '72 kg',
      'Height': '175 cm',
      'BMI': '23.5',
      'Blood Pressure': '120/80 mmHg',
      'Vision': '20/20',
    },
  ),
  MedicalRecordEntity(
    id: '5',
    title: 'Lipid Panel',
    type: 'lab_result',
    description: 'Cholesterol levels slightly elevated. Dietary changes recommended.',
    doctorName: 'Dr. Grace Mwangi',
    date: DateTime.now().subtract(const Duration(days: 45)),
    details: {
      'Total Cholesterol': '215 mg/dL',
      'LDL': '140 mg/dL',
      'HDL': '52 mg/dL',
      'Triglycerides': '160 mg/dL',
    },
  ),
  MedicalRecordEntity(
    id: '6',
    title: 'Metformin 500 mg',
    type: 'prescription',
    description: 'For blood sugar management. Take twice daily with meals.',
    doctorName: 'Dr. James Odhiambo',
    date: DateTime.now().subtract(const Duration(days: 60)),
    details: {
      'Dosage': '500 mg',
      'Frequency': 'Twice daily',
      'Duration': 'Ongoing',
      'Refills': '3',
    },
  ),
  MedicalRecordEntity(
    id: '7',
    title: 'Chest X-Ray',
    type: 'lab_result',
    description: 'Clear lungs, no abnormalities detected.',
    doctorName: 'Dr. Sarah Kimani',
    date: DateTime.now().subtract(const Duration(days: 90)),
    fileUrl: 'https://example.com/xray-001.pdf',
  ),
  MedicalRecordEntity(
    id: '8',
    title: 'Follow-up Visit – Hypertension',
    type: 'visit_summary',
    description:
        'Blood pressure improved to 130/85 mmHg after lifestyle changes. Continue monitoring.',
    doctorName: 'Dr. Grace Mwangi',
    date: DateTime.now().subtract(const Duration(days: 10)),
    details: {
      'Blood Pressure': '130/85 mmHg',
      'Weight': '70 kg',
      'Medication': 'None yet — lifestyle management',
      'Next Visit': '6 weeks',
    },
  ),
];

const _typeMeta = <String, ({String label, IconData icon, Color color})>{
  'lab_result': (
    label: 'Lab',
    icon: Icons.biotech_rounded,
    color: Color(0xFF8B5CF6),
  ),
  'prescription': (
    label: 'Rx',
    icon: Icons.medication_rounded,
    color: Color(0xFFF59E0B),
  ),
  'diagnosis': (
    label: 'Diagnosis',
    icon: Icons.local_hospital_rounded,
    color: Color(0xFFEF4444),
  ),
  'visit_summary': (
    label: 'Visit',
    icon: Icons.description_rounded,
    color: AppColors.primary,
  ),
};

class MedicalRecordListPage extends StatefulWidget {
  const MedicalRecordListPage({super.key});

  @override
  State<MedicalRecordListPage> createState() => _MedicalRecordListPageState();
}

class _MedicalRecordListPageState extends State<MedicalRecordListPage> {
  String _filter = 'all';
  String _query = '';

  List<MedicalRecordEntity> get _filtered {
    Iterable<MedicalRecordEntity> list = _mockRecords;
    if (_filter != 'all') {
      list = list.where((r) => r.type == _filter);
    }
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where(
        (r) =>
            r.title.toLowerCase().contains(q) ||
            (r.doctorName?.toLowerCase().contains(q) ?? false) ||
            (r.description?.toLowerCase().contains(q) ?? false),
      );
    }
    return list.toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: AppColors.mint,
      appBar: AppBar(title: const Text('Medical Records')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search records…',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _Chip(
                    label: 'All',
                    active: _filter == 'all',
                    onTap: () => setState(() => _filter = 'all'),
                  ),
                  _Chip(
                    label: 'Lab results',
                    active: _filter == 'lab_result',
                    onTap: () => setState(() => _filter = 'lab_result'),
                  ),
                  _Chip(
                    label: 'Prescriptions',
                    active: _filter == 'prescription',
                    onTap: () => setState(() => _filter = 'prescription'),
                  ),
                  _Chip(
                    label: 'Diagnoses',
                    active: _filter == 'diagnosis',
                    onTap: () => setState(() => _filter = 'diagnosis'),
                  ),
                  _Chip(
                    label: 'Visits',
                    active: _filter == 'visit_summary',
                    onTap: () => setState(() => _filter = 'visit_summary'),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const _EmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) =>
                        _RecordCard(record: filtered[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Chip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.15),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.folder_open_rounded,
              size: 36,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No records found',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            'Try adjusting your search or filter.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  final MedicalRecordEntity record;
  const _RecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final meta =
        _typeMeta[record.type] ??
        (
          label: record.type,
          icon: Icons.description_rounded,
          color: AppColors.primary,
        );
    final dateStr = DateFormat('MMM d, yyyy').format(record.date);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MedicalRecordDetailPage(record: record),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: meta.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Icon(meta.icon, color: meta.color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            record.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: meta.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            meta.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: meta.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (record.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        record.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (record.doctorName != null) ...[
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.person_rounded,
                            size: 13,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              record.doctorName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
