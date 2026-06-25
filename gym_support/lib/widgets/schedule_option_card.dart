import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:gym_support/core/constants/app_colors.dart';
import 'package:gym_support/core/constants/app_theme.dart';
import 'package:gym_support/models/training_schedule.dart';

class ScheduleOptionCard extends StatelessWidget {
  final TrainingSchedule schedule;
  final bool isSelected;
  final VoidCallback onTap;

  const ScheduleOptionCard({
    super.key,
    required this.schedule,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(14),
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
                  blurRadius: 16, offset: const Offset(0, 4))]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: schedule.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: schedule.color.withValues(alpha: 0.3)),
              ),
              child: Icon(schedule.icon, color: schedule.color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(schedule.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      )),
                  const SizedBox(height: 3),
                  Text(schedule.subtitle,
                      style: TextStyle(
                        color: isSelected ? AppColors.primary : schedule.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      )),
                  const SizedBox(height: 3),
                  Text(schedule.description,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.textSecondary
                            : AppColors.textTertiary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
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
              child: Icon(
                isSelected ? PhosphorIconsBold.check : PhosphorIconsBold.plus,
                color: isSelected ? AppColors.textDark : AppColors.textSecondary,
                size: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
