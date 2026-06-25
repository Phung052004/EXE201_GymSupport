import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_theme.dart';

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
      children: List.generate(totalSteps * 2 - 1, (i) {
        if (i.isOdd) {
          final stepIndex = (i ~/ 2) + 1;
          final filled = stepIndex < currentStep;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 2,
              decoration: BoxDecoration(
                gradient: filled ? AppTheme.cyanGradient : null,
                color: filled ? null : AppColors.outlineStrong,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          );
        }

        final stepIndex = i ~/ 2 + 1;
        final isDone = stepIndex < currentStep;
        final isActive = stepIndex == currentStep;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 30, height: 30,
          decoration: BoxDecoration(
            gradient: (isDone || isActive) ? AppTheme.cyanGradient : null,
            color: (isDone || isActive) ? null : AppColors.surface2,
            shape: BoxShape.circle,
            border: (!isDone && !isActive)
                ? Border.all(color: AppColors.outlineStrong)
                : null,
            boxShadow: isActive
                ? [BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 8)]
                : null,
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, color: AppColors.textDark, size: 14)
                : Text(
                    '$stepIndex',
                    style: TextStyle(
                      color: isActive
                          ? AppColors.textDark
                          : AppColors.textTertiary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ),
        );
      }),
    );
  }
}
