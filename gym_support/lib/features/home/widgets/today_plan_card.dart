import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class TodayPlanCard extends StatelessWidget {
  final VoidCallback onBuildRoutine;
  final Map<String, dynamic>? workout;
  final bool isLoading;

  const TodayPlanCard({
    super.key,
    required this.onBuildRoutine,
    this.workout,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isLoading) ...[
            const Text(
              'Loading plan...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fetching your latest workout from the backend.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.42),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else if (workout == null) ...[
            const Text(
              'No active plan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a new workout to start tracking.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.42),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: onBuildRoutine,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Build Routine',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(width: 5),
                  Icon(Icons.arrow_forward, color: AppColors.primary, size: 17),
                ],
              ),
            ),
          ] else ...[
            _buildWorkoutContent(context),
          ],
        ],
      ),
    );
  }

  Widget _buildWorkoutContent(BuildContext context) {
    final workoutPlan = workout?['workoutPlan'];
    final nutrition = workout?['nutrition'] as Map<String, dynamic>?;

    if (workoutPlan is! List || workoutPlan.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Workout saved, but no day list was returned yet.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.42),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    final selectedDay = workoutPlan.first as Map<String, dynamic>;
    final dayLabel = selectedDay['day']?.toString() ?? 'Today';
    final exercises = selectedDay['exercises'] as List? ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dayLabel,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        if (nutrition != null) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill('Calories', '${nutrition['calories'] ?? '—'}'),
              _pill('Protein', '${nutrition['protein'] ?? '—'}'),
              _pill('Carbs', '${nutrition['carbs'] ?? '—'}'),
              _pill('Fat', '${nutrition['fat'] ?? '—'}'),
            ],
          ),
          const SizedBox(height: 12),
        ],
        ...exercises.map((exercise) {
          final item = exercise as Map<String, dynamic>;
          final name = item['name']?.toString() ?? 'Exercise';
          final muscle = item['muscle']?.toString() ?? 'Unknown';
          final sets = item['sets']?.toString() ?? '—';
          final reps = item['reps']?.toString() ?? '—';

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.fitness_center,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$muscle • $sets sets • $reps reps',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onBuildRoutine,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Build Routine',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(width: 5),
              Icon(Icons.arrow_forward, color: AppColors.primary, size: 17),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.88),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
