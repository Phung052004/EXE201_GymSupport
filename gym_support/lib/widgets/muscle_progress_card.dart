import 'package:flutter/material.dart';
import 'package:gym_support/core/constants/app_colors.dart';

class MuscleProgressGrid extends StatelessWidget {
  const MuscleProgressGrid({super.key});

  Widget _muscleCard(String title, double progress) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2328),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withValues(alpha: 0.06),
            valueColor: AlwaysStoppedAnimation(AppColors.primary),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 3,
      children: [
        _muscleCard('Chest', 0.6),
        _muscleCard('Legs', 0.4),
        _muscleCard('Back', 0.25),
        _muscleCard('Shoulders', 0.8),
        _muscleCard('Arms', 0.35),
        _muscleCard('Core', 0.5),
      ],
    );
  }
}
