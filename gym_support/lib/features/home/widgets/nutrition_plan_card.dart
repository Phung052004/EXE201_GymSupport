import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_theme.dart';

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
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NutritionItem(
                icon: PhosphorIconsBold.fire,
                iconColor: const Color(0xFFFF6B35),
                label: 'Calories',
                value: calories,
              ),
              _NutritionItem(
                icon: PhosphorIconsBold.egg,
                iconColor: AppColors.violet,
                label: 'Protein',
                value: protein,
              ),
              _NutritionItem(
                icon: PhosphorIconsBold.drop,
                iconColor: AppColors.blue,
                label: 'Nước',
                value: water,
              ),
              _NutritionItem(
                icon: PhosphorIconsBold.scales,
                iconColor: AppColors.primary,
                label: 'BMI',
                value: bmi.isEmpty ? '—' : double.tryParse(bmi)?.toStringAsFixed(1) ?? bmi,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NutritionItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _NutritionItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: AppTheme.caption),
      ],
    );
  }
}
