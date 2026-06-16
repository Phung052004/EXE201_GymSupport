import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const StepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (index) {
        final isActive = index < currentStep;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 34 : 22,
          height: 4,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary
                : Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}
