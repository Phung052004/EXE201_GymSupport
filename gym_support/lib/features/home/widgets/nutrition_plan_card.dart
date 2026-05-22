import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class NutritionPlanCard extends StatelessWidget {
  final String calories;
  final String protein;
  final String water;
  final String bmi;

  const NutritionPlanCard({
    super.key,
    required this.calories,
    required this.protein,
    required this.water,
    required this.bmi,
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
        children: [
          Row(
            children: [
              Expanded(
                child: NutritionItem(
                  icon: Icons.local_fire_department,
                  label: 'Calories',
                  value: calories,
                  iconColor: const Color(0xFFFF7A30),
                ),
              ),
              Expanded(
                child: NutritionItem(
                  icon: Icons.egg_alt,
                  label: 'Protein',
                  value: protein,
                  iconColor: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: NutritionItem(
                  icon: Icons.water_drop,
                  label: 'Water',
                  value: water,
                  iconColor: const Color(0xFF248DFF),
                ),
              ),
              Expanded(
                child: NutritionItem(
                  icon: Icons.monitor_weight,
                  label: 'BMI',
                  value: bmi.isEmpty ? '--' : bmi,
                  iconColor: const Color(0xFFC44DFF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class NutritionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  const NutritionItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: 9),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.38),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
