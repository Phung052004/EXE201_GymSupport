import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class EmptyWorkoutView extends StatelessWidget {
  final VoidCallback onBrowseExercises;

  const EmptyWorkoutView({super.key, required this.onBrowseExercises});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.75),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 35,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: Icon(
                Icons.fitness_center_rounded,
                color: Colors.white.withValues(alpha: 0.16),
                size: 36,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Ready to sweat?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your workout queue is currently empty.\nHead over to Exercises to build your routine.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.42),
                fontSize: 14,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 26),
            GestureDetector(
              onTap: onBrowseExercises,
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 28),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.28),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Browse Exercises',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
