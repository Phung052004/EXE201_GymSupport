import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.accent],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.34),
            blurRadius: 30,
            spreadRadius: 1,
          ),
        ],
      ),
      child: const Icon(
        Icons.fitness_center,
        color: AppColors.textDark,
        size: 30,
      ),
    );
  }
}
