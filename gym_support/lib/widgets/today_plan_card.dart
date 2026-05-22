import 'package:flutter/material.dart';
import 'package:gym_support/core/constants/app_colors.dart';

class TodayPlanCard extends StatelessWidget {
  final VoidCallback onBuildRoutine;

  const TodayPlanCard({super.key, required this.onBuildRoutine});

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
        ],
      ),
    );
  }
}
