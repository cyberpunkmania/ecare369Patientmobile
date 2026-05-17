import 'package:flutter/material.dart';

import '../config/theme_config.dart';

/// A single tab descriptor for [PillBottomNav].
class PillNavItem {
  final IconData icon;
  final String label;
  const PillNavItem({required this.icon, required this.label});
}

/// Sleek pill-style bottom navigation:
///
///  • Inactive items are rendered as outlined circles with just the icon
///  • The active item expands into a filled "pill" that shows icon + label
///  • Inactive items sit inside their own circular borders, matching the
///    reference design (mockup)
class PillBottomNav extends StatelessWidget {
  final List<PillNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const PillBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barColor = isDark ? AppColors.darkSurface : Colors.white;
    final ringColor = isDark
        ? AppColors.primaryLight.withValues(alpha: 0.55)
        : AppColors.primary.withValues(alpha: 0.55);
    final iconColor = isDark ? Colors.white : AppColors.textPrimary;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: barColor,
          borderRadius: BorderRadius.circular(48),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : AppColors.primary.withValues(alpha: 0.18),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(items.length, (i) {
            final item = items[i];
            final active = i == currentIndex;
            return _PillNavCell(
              item: item,
              active: active,
              ringColor: ringColor,
              iconColor: iconColor,
              onTap: () => onTap(i),
            );
          }),
        ),
      ),
    );
  }
}

class _PillNavCell extends StatelessWidget {
  final PillNavItem item;
  final bool active;
  final Color ringColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _PillNavCell({
    required this.item,
    required this.active,
    required this.ringColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(36),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        height: 52,
        padding: EdgeInsets.symmetric(horizontal: active ? 18 : 14),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(36),
          border: active ? null : Border.all(color: ringColor, width: 1.4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, size: 22, color: active ? Colors.white : iconColor),
            AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              child: active
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        item.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
