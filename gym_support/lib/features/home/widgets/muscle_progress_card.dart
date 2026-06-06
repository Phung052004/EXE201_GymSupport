import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class MuscleProgressGrid extends StatelessWidget {
  final List<MuscleProgressData> items;
  final bool isLoading;

  const MuscleProgressGrid({
    super.key,
    required this.items,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 84,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          'Hoàn thành buổi tập đầu tiên để bắt đầu ghi nhận tiến độ nhóm cơ.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.48),
            fontSize: 13,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
      );
    }

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
