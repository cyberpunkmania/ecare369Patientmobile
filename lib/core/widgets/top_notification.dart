import 'package:flutter/material.dart';

import '../config/theme_config.dart';

enum NotificationType { success, error, warning, info }

/// Shows an overlay banner at the top of the screen without needing a Scaffold.
class TopNotification {
  TopNotification._();

  static OverlayEntry? _currentEntry;

  static void show(
    BuildContext context,
    String message, {
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    _currentEntry?.remove();

    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (ctx) => _TopNotificationWidget(
        message: message,
        type: type,
        onDismiss: () => _currentEntry?.remove(),
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);

    Future.delayed(duration, () {
      if (_currentEntry == entry) {
        entry.remove();
        _currentEntry = null;
      }
    });
  }
}

class _TopNotificationWidget extends StatelessWidget {
  final String message;
  final NotificationType type;
  final VoidCallback onDismiss;

  const _TopNotificationWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  Color get _backgroundColor {
    switch (type) {
      case NotificationType.success:
        return AppColors.success;
      case NotificationType.error:
        return AppColors.error;
      case NotificationType.warning:
        return AppColors.warning;
      case NotificationType.info:
        return AppColors.info;
    }
  }

  IconData get _icon {
    switch (type) {
      case NotificationType.success:
        return Icons.check_circle_outline;
      case NotificationType.error:
        return Icons.error_outline;
      case NotificationType.warning:
        return Icons.warning_amber_rounded;
      case NotificationType.info:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Positioned(
      top: topPadding,
      left: 16,
      right: 16,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(8),
        color: _backgroundColor,
        child: InkWell(
          onTap: onDismiss,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(_icon, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(Icons.close, color: Colors.white70, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
