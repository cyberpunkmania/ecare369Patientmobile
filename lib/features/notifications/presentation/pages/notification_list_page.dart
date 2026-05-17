import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/theme_config.dart';

// ─────────────────────────────────────────────────────────────
// Static mock notifications
// ─────────────────────────────────────────────────────────────

class _MockNotification {
  final String id;
  final String title;
  final String body;
  final String type; // appointment, chat, result, system
  final bool isRead;
  final DateTime createdAt;

  const _MockNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.isRead = false,
    required this.createdAt,
  });

  _MockNotification copyWith({bool? isRead}) => _MockNotification(
    id: id,
    title: title,
    body: body,
    type: type,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt,
  );
}

final List<_MockNotification> _mockNotifications = [
  _MockNotification(
    id: '1',
    title: 'Appointment Confirmed',
    body:
        'Your appointment with Dr. Sarah Kimani on April 15 at 10:00 AM has been confirmed.',
    type: 'appointment',
    isRead: false,
    createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
  ),
  _MockNotification(
    id: '2',
    title: 'Lab Results Ready',
    body:
        'Your blood test results from April 10 are now available. Tap to view.',
    type: 'result',
    isRead: false,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  _MockNotification(
    id: '3',
    title: 'New Message',
    body: 'Dr. James Odhiambo sent you a message about your follow-up.',
    type: 'chat',
    isRead: false,
    createdAt: DateTime.now().subtract(const Duration(hours: 4)),
  ),
  _MockNotification(
    id: '4',
    title: 'Medication Reminder',
    body: 'Time to take your evening medication: Amoxicillin 500mg.',
    type: 'system',
    isRead: true,
    createdAt: DateTime.now().subtract(const Duration(hours: 8)),
  ),
  _MockNotification(
    id: '5',
    title: 'Appointment Rescheduled',
    body:
        'Your appointment with Dr. Amina Hassan has been moved to April 18 at 2:30 PM.',
    type: 'appointment',
    isRead: true,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  _MockNotification(
    id: '6',
    title: 'Payment Received',
    body:
        'Payment of KES 1,500 for consultation with Dr. Peter Mwangi has been received.',
    type: 'system',
    isRead: true,
    createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 6)),
  ),
  _MockNotification(
    id: '7',
    title: 'Prescription Updated',
    body:
        'Dr. Lucy Wanjiku has updated your prescription. Please review the changes.',
    type: 'result',
    isRead: true,
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
  ),
  _MockNotification(
    id: '8',
    title: 'Welcome to E-Care 369',
    body:
        'Thank you for joining! Complete your profile to get the most out of the app.',
    type: 'system',
    isRead: true,
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
  ),
];

class NotificationListPage extends StatefulWidget {
  const NotificationListPage({super.key});

  @override
  State<NotificationListPage> createState() => _NotificationListPageState();
}

class _NotificationListPageState extends State<NotificationListPage> {
  late List<_MockNotification> _notifications;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _notifications = List.of(_mockNotifications);
  }

  void _markAllRead() {
    setState(() {
      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
    });
  }

  void _markRead(String id) {
    setState(() {
      _notifications = [
        for (final n in _notifications)
          if (n.id == id) n.copyWith(isRead: true) else n,
      ];
    });
  }

  void _openDetail(_MockNotification notification) {
    _markRead(notification.id);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NotificationDetailSheet(notification: notification),
    );
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  List<_MockNotification> get _filtered {
    if (_filter == 'all') return _notifications;
    if (_filter == 'unread')
      return _notifications.where((n) => !n.isRead).toList();
    return _notifications.where((n) => n.type == _filter).toList();
  }

  Map<String, List<_MockNotification>> _grouped(List<_MockNotification> list) {
    final today = <_MockNotification>[];
    final week = <_MockNotification>[];
    final older = <_MockNotification>[];
    final now = DateTime.now();
    for (final n in list) {
      final diff = now.difference(n.createdAt);
      if (diff.inHours < 24) {
        today.add(n);
      } else if (diff.inDays < 7) {
        week.add(n);
      } else {
        older.add(n);
      }
    }
    return {
      if (today.isNotEmpty) 'Today': today,
      if (week.isNotEmpty) 'This week': week,
      if (older.isNotEmpty) 'Earlier': older,
    };
  }

  @override
  Widget build(BuildContext context) {
    final groups = _grouped(_filtered);

    return Scaffold(
      backgroundColor: AppColors.mint,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                onPressed: _markAllRead,
                icon: const Icon(Icons.done_all_rounded, size: 18),
                label: const Text('Mark all read'),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _NotifFilter(
                    label: 'All',
                    count: _notifications.length,
                    active: _filter == 'all',
                    onTap: () => setState(() => _filter = 'all'),
                  ),
                  _NotifFilter(
                    label: 'Unread',
                    count: _unreadCount,
                    active: _filter == 'unread',
                    onTap: () => setState(() => _filter = 'unread'),
                  ),
                  _NotifFilter(
                    label: 'Appointments',
                    active: _filter == 'appointment',
                    onTap: () => setState(() => _filter = 'appointment'),
                  ),
                  _NotifFilter(
                    label: 'Results',
                    active: _filter == 'result',
                    onTap: () => setState(() => _filter = 'result'),
                  ),
                  _NotifFilter(
                    label: 'System',
                    active: _filter == 'system',
                    onTap: () => setState(() => _filter = 'system'),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _filtered.isEmpty
                ? const _EmptyNotif()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    children: [
                      for (final entry in groups.entries) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Column(
                            children: [
                              for (int i = 0; i < entry.value.length; i++) ...[
                                _NotificationTile(
                                  notification: entry.value[i],
                                  onTap: () => _openDetail(entry.value[i]),
                                ),
                                if (i != entry.value.length - 1)
                                  const Divider(
                                    height: 1,
                                    indent: 70,
                                    endIndent: 16,
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _NotifFilter extends StatelessWidget {
  final String label;
  final int? count;
  final bool active;
  final VoidCallback onTap;
  const _NotifFilter({
    required this.label,
    required this.active,
    required this.onTap,
    this.count,
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
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: active ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              if (count != null && count! > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? Colors.white.withValues(alpha: 0.25)
                        : AppColors.mint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: active ? Colors.white : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyNotif extends StatelessWidget {
  const _EmptyNotif();

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
              Icons.notifications_none_rounded,
              size: 36,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'You\'re all caught up',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            'No notifications in this view.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final _MockNotification notification;
  final VoidCallback onTap;
  const _NotificationTile({required this.notification, required this.onTap});

  IconData _icon(String type) {
    switch (type) {
      case 'appointment':
        return Icons.calendar_today_rounded;
      case 'chat':
        return Icons.chat_bubble_rounded;
      case 'result':
        return Icons.biotech_rounded;
      case 'system':
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _color(String type) {
    switch (type) {
      case 'appointment':
        return AppColors.primary;
      case 'chat':
        return AppColors.info;
      case 'result':
        return const Color(0xFF8B5CF6);
      case 'system':
      default:
        return AppColors.warning;
    }
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return DateFormat('MMM d').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(notification.type);
    final unread = !notification.isRead;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(_icon(notification.type), color: color, size: 20),
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
                          notification.title,
                          style: TextStyle(
                            fontWeight: unread
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        _formatTime(notification.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: unread
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontWeight: unread
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            if (unread) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 18),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Notification detail sheet
// ─────────────────────────────────────────────────────────────

class _NotificationDetailSheet extends StatelessWidget {
  final _MockNotification notification;
  const _NotificationDetailSheet({required this.notification});

  IconData _icon(String type) {
    switch (type) {
      case 'appointment':
        return Icons.calendar_today_rounded;
      case 'chat':
        return Icons.chat_bubble_rounded;
      case 'result':
        return Icons.biotech_rounded;
      case 'system':
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _color(String type) {
    switch (type) {
      case 'appointment':
        return AppColors.primary;
      case 'chat':
        return AppColors.info;
      case 'result':
        return const Color(0xFF8B5CF6);
      case 'system':
      default:
        return AppColors.warning;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'appointment':
        return 'Appointment';
      case 'chat':
        return 'Message';
      case 'result':
        return 'Lab / Result';
      case 'system':
      default:
        return 'System';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(notification.type);
    final fmt = DateFormat('d MMM yyyy, h:mm a');

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
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
          const SizedBox(height: 20),

          // Icon + type badge row
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(_icon(notification.type), color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _typeLabel(notification.type),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            notification.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          // Timestamp
          Text(
            fmt.format(notification.createdAt),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const Divider(height: 24),

          // Body
          Text(
            notification.body,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),

          // Close button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
