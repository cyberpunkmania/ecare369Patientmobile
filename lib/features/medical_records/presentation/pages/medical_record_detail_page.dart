import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/theme_config.dart';
import '../../domain/entities/medical_record_entity.dart';

class MedicalRecordDetailPage extends StatelessWidget {
  final MedicalRecordEntity record;

  const MedicalRecordDetailPage({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMMM d, yyyy').format(record.date);

    return Scaffold(
      appBar: AppBar(title: const Text('Record Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              record.title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Chip(
              label: Text(record.type.replaceAll('_', ' ').toUpperCase()),
              backgroundColor: AppColors.primary.withOpacity(0.1),
              labelStyle: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 20),

            // Info rows
            _InfoRow(label: 'Date', value: dateStr),
            if (record.doctorName != null)
              _InfoRow(label: 'Doctor', value: record.doctorName!),
            if (record.description != null)
              _InfoRow(label: 'Description', value: record.description!),

            // Details map
            if (record.details != null && record.details!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Details',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Divider(),
              ...record.details!.entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          e.key,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(child: Text(e.value.toString())),
                    ],
                  ),
                ),
              ),
            ],

            // File link
            if (record.fileUrl != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.file_download),
                  label: const Text('View / Download File'),
                  onPressed: () {
                    // TODO: open file URL with url_launcher
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }
}
