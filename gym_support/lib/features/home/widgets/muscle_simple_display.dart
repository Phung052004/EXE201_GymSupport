import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/app_colors.dart';
import 'muscle_progress_card.dart';
import 'rank_image.dart';
import 'muscle_detail_modal.dart';

class MuscleSimpleDisplay extends StatefulWidget {
  final List<MuscleProgressData> items;
  final bool isLoading;

  const MuscleSimpleDisplay({
    required this.items,
    this.isLoading = false,
  });

  @override
  State<MuscleSimpleDisplay> createState() => _MuscleSimpleDisplayState();
}

class _MuscleSimpleDisplayState extends State<MuscleSimpleDisplay> {
  String? _selectedMuscleId;

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

  void _showMuscleDetail(MuscleProgressData muscle) {
    showDialog(
      context: context,
      builder: (context) => MuscleDetailModal(
        data: muscle,
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        height: 300,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (widget.items.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              PhosphorIconsBold.person,
              color: AppColors.textTertiary,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Chưa có dữ liệu tiến độ',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    // Sort by level desc
    final sorted = [...widget.items]..sort((a, b) => b.level.compareTo(a.level));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineStrong.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rank assets grid (top 6 muscles)
          Text(
            'Rank Assets',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 6,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.85,
            children: [
              for (int i = 0; i < (sorted.length > 6 ? 6 : sorted.length); i++)
                GestureDetector(
                  onTap: () {
                    setState(() => _selectedMuscleId = sorted[i].id);
                    _showMuscleDetail(sorted[i]);
                  },
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: _selectedMuscleId == sorted[i].id
                              ? [
                                  BoxShadow(
                                    color: _getTierColor(sorted[i].tier)
                                        .withValues(alpha: 0.4),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: RankImage(
                          tier: sorted[i].tier,
                          size: 50,
                          isSelected: _selectedMuscleId == sorted[i].id,
                          showContainer: true,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        sorted[i].name.split(' ').first,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          // Muscle list
          Text(
            'Nhóm Cơ Bắp',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              final muscle = sorted[index];
              final tc = _getTierColor(muscle.tier);
              final isSelected = _selectedMuscleId == muscle.id;

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedMuscleId = muscle.id);
                  _showMuscleDetail(muscle);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? tc.withValues(alpha: 0.1)
                        : AppColors.background.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: tc.withValues(
                        alpha: isSelected ? 0.3 : 0.1,
                      ),
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: tc.withValues(alpha: 0.15),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      // Rank indicator
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: tc.withValues(alpha: 0.2),
                          border: Border.all(
                            color: tc.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Lv.${muscle.level}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: tc,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
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
                              muscle.name,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: tc,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  muscle.tier.toUpperCase(),
                                  style: TextStyle(
                                    color: tc,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Progress and XP
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${(muscle.progress * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: tc,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '${muscle.totalExp} XP',
                            style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        PhosphorIconsBold.caretRight,
                        color: tc.withValues(
                          alpha: isSelected ? 1.0 : 0.3,
                        ),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
