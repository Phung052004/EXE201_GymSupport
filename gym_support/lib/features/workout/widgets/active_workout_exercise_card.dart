import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/exercise.dart';

class ActiveWorkoutExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final bool isCompleted;
  final VoidCallback onToggleComplete;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const ActiveWorkoutExerciseCard({
    super.key,
    required this.exercise,
    required this.isCompleted,
    required this.onToggleComplete,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onEdit,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: isCompleted
                ? AppColors.primary.withValues(alpha: 0.45)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: onToggleComplete,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: isCompleted
                        ? AppColors.primary
                        : Colors.white.withValues(alpha: 0.22),
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? const Icon(
                        Icons.check,
                        color: AppColors.textDark,
                        size: 16,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: TextStyle(
                      color: isCompleted
                          ? Colors.white.withValues(alpha: 0.45)
                          : Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'TARGET: ${exercise.muscleGroup.toUpperCase()}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.36),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      WorkoutBadge(
                        text: exercise.setsAndReps.split(' x ').first,
                      ),
                      const SizedBox(width: 7),
                      WorkoutBadge(
                        text: exercise.setsAndReps.contains(' x ')
                            ? exercise.setsAndReps.split(' x ').last
                            : exercise.setsAndReps,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onRemove,
              child: Icon(
                Icons.close_rounded,
                color: Colors.white.withValues(alpha: 0.28),
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WorkoutBadge extends StatelessWidget {
  final String text;

  const WorkoutBadge({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
