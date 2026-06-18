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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: NutritionItem(
                  icon: Icons.local_fire_department_rounded,
                  label: 'Calories',
                  value: calories,
                  iconColor: const Color(0xFFFF7A30),
                ),
              ),
              Expanded(
                child: NutritionItem(
                  icon: Icons.egg_alt_rounded,
                  label: 'Protein',
                  value: protein,
                  iconColor: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: NutritionItem(
                  icon: Icons.water_drop_rounded,
                  label: 'Water',
                  value: water,
                  iconColor: const Color(0xFF248DFF),
                ),
              ),
              Expanded(
                child: NutritionItem(
                  icon: Icons.monitor_weight_rounded,
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
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
