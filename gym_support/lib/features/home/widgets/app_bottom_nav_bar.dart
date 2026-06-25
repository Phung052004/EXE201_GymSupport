import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/app_colors.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    _NavItem(active: PhosphorIconsBold.house,         inactive: PhosphorIconsRegular.house,         label: 'Home'),
    _NavItem(active: PhosphorIconsBold.sparkle,       inactive: PhosphorIconsRegular.sparkle,       label: 'AI Coach'),
    _NavItem(active: PhosphorIconsBold.barbell,       inactive: PhosphorIconsRegular.barbell,       label: 'Workout'),
    _NavItem(active: PhosphorIconsBold.calendarCheck, inactive: PhosphorIconsRegular.calendarCheck, label: 'Routine'),
    _NavItem(active: PhosphorIconsBold.user,          inactive: PhosphorIconsRegular.user,          label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          top: BorderSide(color: AppColors.outline, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final selected = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          selected ? item.active : item.inactive,
                          size: 22,
                          color: selected ? AppColors.primary : AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          color: selected ? AppColors.primary : AppColors.textTertiary,
                          fontSize: 9.5,
                          fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                          letterSpacing: selected ? 0.2 : 0,
                        ),
                        child: Text(item.label),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData active;
  final IconData inactive;
  final String label;
  const _NavItem({required this.active, required this.inactive, required this.label});
}
