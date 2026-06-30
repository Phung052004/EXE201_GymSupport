import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/app_colors.dart';
import 'muscle_progress_card.dart';

class MuscleProgressTeaser extends StatelessWidget {
  final List<MuscleProgressData> items;
  final bool isLoading;
  final VoidCallback onViewAll;

  const MuscleProgressTeaser({
    required this.items,
    required this.onViewAll,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _LoadingTeaser();
    }

    if (items.isEmpty) {
      return _EmptyTeaser(onViewAll: onViewAll);
    }

    // Sort by level desc
    final sorted = [...items]..sort((a, b) => b.level.compareTo(a.level));
    final topMuscles = sorted.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineStrong.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          // Top stats
          Row(
            children: [
              Expanded(
                child: _TeaseStatItem(
                  label: 'Cơ bắp',
                  value: '${items.length}',
                  icon: PhosphorIconsBold.person,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TeaseStatItem(
                  label: 'Cao nhất',
                  value: 'Lv.${sorted.first.level}',
                  icon: PhosphorIconsBold.crown,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TeaseStatItem(
                  label: 'Yếu nhất',
                  value: 'Lv.${sorted.last.level}',
                  icon: PhosphorIconsBold.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Top 3 muscles mini cards
          Column(
            children: [
              for (int i = 0; i < topMuscles.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                _MiniMuscleCard(
                  muscle: topMuscles[i],
                  index: i + 1,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          // View all button
          GestureDetector(
            onTap: onViewAll,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.primary.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Xem chi tiết',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(
                    PhosphorIconsBold.arrowRight,
                    color: AppColors.primary,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeaseStatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _TeaseStatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMuscleCard extends StatefulWidget {
  final MuscleProgressData muscle;
  final int index;

  const _MiniMuscleCard({
    required this.muscle,
    required this.index,
  });

  @override
  State<_MiniMuscleCard> createState() => _MiniMuscleCardState();
}

class _MiniMuscleCardState extends State<_MiniMuscleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tc = _getTierColor(widget.muscle.tier);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tc.withValues(alpha: 0.06),
            tc.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tc.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          // Rank circle
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tc.withValues(alpha: 0.15),
              border: Border.all(
                color: tc.withValues(alpha: 0.25),
              ),
            ),
            child: Center(
              child: Text(
                widget.index.toString(),
                style: TextStyle(
                  color: tc,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Muscle info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.muscle.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: AnimatedBuilder(
                    animation: _animController,
                    builder: (context, child) {
                      return LinearProgressIndicator(
                        value: widget.muscle.progress.clamp(0.0, 1.0),
                        backgroundColor:
                            AppColors.background.withValues(alpha: 0.3),
                        valueColor: AlwaysStoppedAnimation(
                          tc.withValues(
                            alpha: 0.5 +
                                _animController.value * 0.3,
                          ),
                        ),
                        minHeight: 4,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Level badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: tc.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Lv.${widget.muscle.level}',
              style: TextStyle(
                color: tc,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingTeaser extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          for (int i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyTeaser extends StatelessWidget {
  final VoidCallback onViewAll;

  const _EmptyTeaser({required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            PhosphorIconsBold.person,
            color: AppColors.textTertiary,
            size: 32,
          ),
          const SizedBox(height: 12),
          const Text(
            'Chưa có tiến độ cơ bắp',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onViewAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Xem chi tiết',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _getTierColor(String tier) {
  switch (tier.toLowerCase()) {
    case 'bronze':
      return const Color(0xFFCD7F32);
    case 'silver':
      return const Color(0xFFA8A8A8);
    case 'gold':
      return const Color(0xFFFFCC00);
    case 'platinum':
      return const Color(0xFFE2E8F0);
    case 'diamond':
      return const Color(0xFF2196F3);
    case 'champion':
      return const Color(0xFF9C27B0);
    default:
      return const Color(0xFF555555);
  }
}
