import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/exercise.dart';

class ExerciseListItem extends StatelessWidget {
  final Exercise exercise;
  final bool isSelected;
  final VoidCallback onToggle;

  const ExerciseListItem({
    super.key,
    required this.exercise,
    required this.isSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.65)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(exercise.icon, color: AppColors.primary, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      exercise.muscleGroup.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '  •  ${exercise.setsAndReps}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.36),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.videocam_rounded,
            color: AppColors.primary.withValues(alpha: 0.8),
            size: 18,
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Icon(
                isSelected ? Icons.check_rounded : Icons.add_rounded,
                color: isSelected
                    ? AppColors.textDark
                    : Colors.white.withValues(alpha: 0.42),
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
