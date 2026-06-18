import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class OnboardingTitle extends StatelessWidget {
  const OnboardingTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Welcome to GymSupport',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 26,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
