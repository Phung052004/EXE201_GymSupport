import 'package:flutter/material.dart';
import 'package:gym_support/core/constants/app_colors.dart';
import 'package:gym_support/core/constants/app_theme.dart';

class GenderButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const GenderButton({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 50,
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.cyanGradient : null,
          color: isSelected ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.5)
                : AppColors.outlineStrong,
          ),
          boxShadow: isSelected
              ? [BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 10, offset: const Offset(0, 3))]
              : null,
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? AppColors.textDark : AppColors.textSecondary,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
