import 'package:flutter/material.dart';

import 'package:gym_support/core/constants/app_colors.dart';
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
        duration: const Duration(milliseconds: 220),
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceSelected : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Colors.white.withValues(alpha: 0.03),
            width: 1.3,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: schedule.color.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(schedule.icon, color: schedule.color, size: 25),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    schedule.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    schedule.subtitle,
                    style: TextStyle(
                      color: schedule.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    schedule.description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSelected ? Icons.check : Icons.add,
                color: isSelected
                    ? AppColors.textDark
                    : Colors.white.withValues(alpha: 0.45),
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
