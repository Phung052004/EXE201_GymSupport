import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_theme.dart';

class WeeklyActivityCard extends StatelessWidget {
  final bool isLoading;
  final int weeklyCount;

  const WeeklyActivityCard({
    super.key,
    this.isLoading = false,
    this.weeklyCount = 0,
  });

  static const _days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().weekday; // 1=Mon ... 7=Sun

    if (isLoading) {
      return SkeletonBox(width: double.infinity, height: 106, radius: AppTheme.radiusLg);
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: AppTheme.cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Count block
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tuần này',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$weeklyCount',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'buổi',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 18),
          // Day dots — fill remaining width
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (i) {
                    final dayIndex = i + 1;
                    final isToday = dayIndex == today;
                    final isPast = dayIndex < today;
                    return _DayDot(
                      label: _days[i],
                      isToday: isToday,
                      isPast: isPast,
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  final String label;
  final bool isToday;
  final bool isPast;

  const _DayDot({required this.label, required this.isToday, required this.isPast});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: isToday
                ? AppColors.primary
                : isPast
                    ? AppColors.primary.withValues(alpha: 0.18)
                    : AppColors.surface2,
            shape: BoxShape.circle,
            border: isToday
                ? null
                : Border.all(
                    color: isPast
                        ? AppColors.primary.withValues(alpha: 0.35)
                        : AppColors.outlineStrong,
                    width: 1.5,
                  ),
          ),
          child: (isPast || isToday)
              ? Icon(
                  PhosphorIconsBold.check,
                  size: 14,
                  color: isToday ? AppColors.textDark : AppColors.primary,
                )
              : null,
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isToday ? AppColors.primary : AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}
