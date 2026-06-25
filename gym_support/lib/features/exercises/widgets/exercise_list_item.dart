import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/exercise.dart';
import '../../workout/widgets/exercise_picker_card.dart';

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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.65)
              : Colors.white.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 8,
            child: exercise.imageUrl.isEmpty
                ? Container(
                    color: AppColors.background.withValues(alpha: 0.65),
                    child: Icon(
                      exercise.icon,
                      color: AppColors.primary,
                      size: 34,
                    ),
                  )
                : Image.network(
                    exercise.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.background.withValues(alpha: 0.65),
                      child: Icon(
                        exercise.icon,
                        color: AppColors.primary,
                        size: 34,
                      ),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(13),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
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
                            exercise.setsAndReps,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.42),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () =>
                            showExerciseDetailSheet(context, exercise),
                        icon: const Icon(PhosphorIconsBold.eye, size: 16),
                        label: const Text('View Detail'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: onToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 42,
                    height: 42,
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
                      isSelected ? PhosphorIconsBold.check : PhosphorIconsBold.plus,
                      color: isSelected
                          ? AppColors.textDark
                          : Colors.white.withValues(alpha: 0.42),
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
