import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/constants/app_colors.dart';

class SchedulingCard extends StatelessWidget {
  const SchedulingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          const Icon(
            PhosphorIconsBold.calendarCheck,
            color: AppColors.primary,
            size: 17,
          ),
          const SizedBox(width: 9),
          Text(
            'Scheduling for: ',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.48),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Text(
            'Today',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          Icon(
            PhosphorIconsBold.caretRight,
            color: Colors.white.withValues(alpha: 0.35),
            size: 22,
          ),
        ],
      ),
    );
  }
}
