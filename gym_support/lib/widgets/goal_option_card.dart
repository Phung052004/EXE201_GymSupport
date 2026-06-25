import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:gym_support/core/constants/app_colors.dart';
import 'package:gym_support/core/constants/app_theme.dart';
import '../models/fitness_goal.dart';

class GoalOptionCard extends StatelessWidget {
  final FitnessGoal goal;
  final bool isSelected;
  final VoidCallback onTap;

  const GoalOptionCard({
    super.key,
    required this.goal,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.heroGradient : null,
          color: isSelected ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.6)
                : AppColors.outline,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  blurRadius: 14, offset: const Offset(0, 4))]
              : null,
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? goal.color.withValues(alpha: 0.18)
                    : AppColors.surface2,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: goal.color.withValues(alpha: 0.4))
                    : null,
              ),
              child: Icon(goal.icon,
                  color: isSelected ? goal.color : AppColors.textSecondary,
                  size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(goal.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      )),
                  const SizedBox(height: 3),
                  Text(goal.subtitle,
                      style: TextStyle(
                        color: isSelected ? goal.color : AppColors.textTertiary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      )),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28, height: 28,
              decoration: BoxDecoration(
                gradient: isSelected ? AppTheme.cyanGradient : null,
                color: isSelected ? null : AppColors.surface2,
                shape: BoxShape.circle,
                border: isSelected
                    ? null
                    : Border.all(color: AppColors.outlineStrong),
              ),
              child: isSelected
                  ? const Icon(PhosphorIconsBold.check,
                      color: AppColors.textDark, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
