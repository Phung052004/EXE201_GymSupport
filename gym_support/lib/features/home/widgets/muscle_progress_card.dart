import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class MuscleProgressGrid extends StatelessWidget {
  const MuscleProgressGrid({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      MuscleProgressData(
        name: 'Chest',
        level: 'Lv 2',
        progress: 0.42,
        xp: '60/150 XP',
      ),
      MuscleProgressData(
        name: 'Legs',
        level: 'Lv 1',
        progress: 0.78,
        xp: '80/100 XP',
      ),
      MuscleProgressData(
        name: 'Back',
        level: 'Lv 2',
        progress: 0.70,
        xp: '120/150 XP',
      ),
      MuscleProgressData(
        name: 'Shoulders',
        level: 'Lv 1',
        progress: 0.90,
        xp: '90/100 XP',
      ),
      MuscleProgressData(
        name: 'Arms',
        level: 'Lv 4',
        progress: 0.18,
        xp: '15/100 XP',
      ),
    ];

    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 84,
      ),
      itemBuilder: (context, index) {
        return MuscleProgressCard(data: items[index]);
      },
    );
  }
}

class MuscleProgressCard extends StatelessWidget {
  final MuscleProgressData data;

  const MuscleProgressCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  data.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                data.level,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          const Spacer(),

          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: data.progress,
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),

          const SizedBox(height: 7),

          Align(
            alignment: Alignment.centerRight,
            child: Text(
              data.xp,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.32),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MuscleProgressData {
  final String name;
  final String level;
  final double progress;
  final String xp;

  const MuscleProgressData({
    required this.name,
    required this.level,
    required this.progress,
    required this.xp,
  });
}
