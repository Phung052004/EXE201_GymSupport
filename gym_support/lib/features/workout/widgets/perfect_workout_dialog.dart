import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class PerfectWorkoutDialog extends StatelessWidget {
  final int exerciseCount;
  final VoidCallback onGoHome;

  const PerfectWorkoutDialog({
    super.key,
    required this.exerciseCount,
    required this.onGoHome,
  });

  @override
  Widget build(BuildContext context) {
    final calories = exerciseCount * 12;
    final minutes = exerciseCount * 5;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF20232B),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.12),
              blurRadius: 38,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 19,
                  ),
                ),
              ),
            ),
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.emoji_events,
                color: AppColors.textDark,
                size: 38,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              '🎉 Perfect Workout!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Amazing job! You crushed every single exercise!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: DialogStatCard(
                    icon: Icons.bolt,
                    label: 'EXERCISES',
                    value: '$exerciseCount/$exerciseCount',
                    iconColor: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DialogStatCard(
                    icon: Icons.show_chart,
                    label: 'MINUTES',
                    value: '$minutes',
                    iconColor: const Color(0xFF248DFF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DialogStatCard(
                    icon: Icons.local_fire_department,
                    label: 'CALORIES',
                    value: '$calories',
                    iconColor: const Color(0xFFFF7A30),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: DialogStatCard(
                    icon: Icons.star,
                    label: 'COMPLETION',
                    value: '100%',
                    iconColor: Color(0xFFFFD43B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.18),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.flash_on,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'EXP GAINED',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    '+80 XP',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: onGoHome,
              child: Container(
                height: 54,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.home_rounded,
                        color: AppColors.textDark,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Go Home',
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Keep making progress, no matter how small!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DialogStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  const DialogStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
