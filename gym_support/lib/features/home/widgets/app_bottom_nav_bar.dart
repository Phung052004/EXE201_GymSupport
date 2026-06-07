import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      const BottomNavItemData(icon: Icons.home_rounded, label: 'Home'),
      const BottomNavItemData(icon: Icons.smart_toy_rounded, label: 'AI'),
      const BottomNavItemData(
        icon: Icons.fitness_center_rounded,
        label: 'Workout',
      ),
      const BottomNavItemData(
        icon: Icons.calendar_month_rounded,
        label: 'Routine',
      ),
      const BottomNavItemData(icon: Icons.person_rounded, label: 'Profile'),
    ];

    return SafeArea(
      top: false,
      child: Container(
        height: 74,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: Color(0xFF2F3440), width: 1)),
        ),
        child: Row(
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isSelected = currentIndex == index;

            return Expanded(
              child: BottomNavItem(
                item: item,
                isSelected: isSelected,
                onTap: () => onTap(index),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class BottomNavItem extends StatelessWidget {
  final BottomNavItemData item;
  final bool isSelected;
  final VoidCallback onTap;

  const BottomNavItem({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.primary;
    final inactiveColor = Colors.white.withValues(alpha: 0.32);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            item.icon,
            color: isSelected ? activeColor : inactiveColor,
            size: 22,
          ),
          const SizedBox(height: 4),
          Text(
            item.label,
            style: TextStyle(
              color: isSelected ? activeColor : inactiveColor,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class BottomNavItemData {
  final IconData icon;
  final String label;

  const BottomNavItemData({required this.icon, required this.label});
}
