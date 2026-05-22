import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class ExerciseHeader extends StatelessWidget {
  final String goal;
  final String schedule;
  final VoidCallback onAdd;

  const ExerciseHeader({
    super.key,
    required this.goal,
    required this.schedule,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Exercises',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.28),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.add, color: AppColors.textDark, size: 26),
          ),
        ),
      ],
    );
  }
}

class ExerciseInfoChips extends StatelessWidget {
  final String goal;
  final String schedule;

  const ExerciseInfoChips({
    super.key,
    required this.goal,
    required this.schedule,
  });

  @override
  Widget build(BuildContext context) {
    final goals = goal
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...goals.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: _InfoChip(
                    icon: Icons.bolt,
                    text: item.toUpperCase(),
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          );
        }),
        Row(
          children: [
            Expanded(
              child: _InfoChip(
                icon: Icons.calendar_month,
                text: schedule.toUpperCase(),
                color: const Color(0xFF248DFF),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 30),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
