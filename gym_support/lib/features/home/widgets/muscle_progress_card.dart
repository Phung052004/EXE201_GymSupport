import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_theme.dart' show SkeletonBox, AppTheme;
import 'muscle_progress_painter.dart';
import 'rank_image.dart';

class MuscleProgressData {
  final String id;
  final String name;
  final String category;
  final int level;
  final int totalExp;
  final int currentLevelExp;
  final int expToNextLevel;
  final double progress;
  final String tier;
  final bool isLagging;

  const MuscleProgressData({
    required this.id,
    required this.name,
    required this.category,
    required this.level,
    required this.totalExp,
    required this.currentLevelExp,
    required this.expToNextLevel,
    required this.progress,
    required this.tier,
    required this.isLagging,
  });
}

class _MuscleItemCard extends StatefulWidget {
  final MuscleProgressData data;
  final VoidCallback onTap;
  final bool isExpanded;

  const _MuscleItemCard({
    required this.data,
    required this.onTap,
    this.isExpanded = false,
  });

  @override
  State<_MuscleItemCard> createState() => _MuscleItemCardState();
}

class _MuscleItemCardState extends State<_MuscleItemCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    if (widget.isExpanded) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(_MuscleItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded && !oldWidget.isExpanded) {
      _animationController.forward();
    } else if (!widget.isExpanded && oldWidget.isExpanded) {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tc = _tierColor(widget.data.tier);
    final data = widget.data;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  tc.withValues(alpha: 0.05 + _animationController.value * 0.05),
                  tc.withValues(alpha: 0.02 + _animationController.value * 0.02),
                ],
              ),
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: tc.withValues(
                  alpha: 0.15 + _animationController.value * 0.15,
                ),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: tc.withValues(
                    alpha: 0.08 + _animationController.value * 0.12,
                  ),
                  blurRadius: 12 + _animationController.value * 8,
                  offset: Offset(0, 2 + _animationController.value * 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: [
                  // Header - always visible
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Left: Rank badge
                        Container(
                          width: 60,
                          height: 60,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.background.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: tc.withValues(alpha: 0.2),
                            ),
                          ),
                          child: RankImage(
                            tier: data.tier,
                            size: 48,
                            isSelected: widget.isExpanded,
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Middle: Name and progress
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data.name,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              MuscleProgressBar(
                                value: data.progress.clamp(0.0, 1.0),
                                color: tc,
                                height: 6,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${(data.progress * 100).toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      color: tc,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    '${data.currentLevelExp}/${data.expToNextLevel}',
                                    style: const TextStyle(
                                      color: AppColors.textTertiary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Right: Level and tier
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            MuscleLevel(
                              level: data.level,
                              tierColor: tc,
                              isLagging: data.isLagging,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              data.tier.toUpperCase(),
                              style: TextStyle(
                                color: tc,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Expanded content
                  if (widget.isExpanded) ...[
                    Container(
                      height: 1,
                      color: tc.withValues(alpha: 0.1),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Detailed stats
                          Row(
                            children: [
                              Expanded(
                                child: _StatBox(
                                  label: 'Tổng XP',
                                  value: data.totalExp.toString(),
                                  color: tc,
                                  icon: PhosphorIconsBold.lightning,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatBox(
                                  label: 'Cấp độ',
                                  value: 'Lv.${data.level}',
                                  color: tc,
                                  icon: PhosphorIconsBold.star,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (data.isLagging)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.danger.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.danger.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    PhosphorIconsBold.warning,
                                    color: AppColors.danger,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Cơ bắp này đang yếu hơn những cơ khác. Tăng tập luyện để cân bằng',
                                      style: TextStyle(
                                        color: AppColors.danger,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

Color _tierColor(String tier) {
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
      return AppColors.primary;
    case 'champion':
      return const Color(0xFF9C27B0);
    default:
      return const Color(0xFF555555);
  }
}

(bool isFront, String path)? _muscleToMask(String name) {
  final n = name.toLowerCase().trim();

  if (n.contains('chest') || n.contains('ngực')) {
    return (true, 'assets/body/masks/front_chest.png');
  }
  if (n.contains('bicep') || n.contains('nhị đầu')) {
    return (true, 'assets/body/masks/front_biceps.png');
  }
  if (n.contains('quad') || n.contains('đùi trước')) {
    return (true, 'assets/body/masks/front_quads.png');
  }
  if (n.contains('abs') || n.contains('bụng') || n.contains('abdomin')) {
    return (true, 'assets/body/masks/front_abs.png');
  }
  if (n.contains('core')) {
    return (true, 'assets/body/masks/front_core.png');
  }
  if (n.contains('oblique')) {
    return (true, 'assets/body/masks/front_obliques.png');
  }
  if (n.contains('forearm') || n.contains('cẳng tay')) {
    return (true, 'assets/body/masks/front_forearms.png');
  }
  if (n.contains('calf') || n.contains('calves') || n.contains('bắp chân')) {
    return (true, 'assets/body/masks/front_calves.png');
  }
  if (n.contains('adductor')) {
    return (true, 'assets/body/masks/front_adductors.png');
  }
  if (n.contains('anterior delt') || n.contains('front delt') || n.contains('vai trước')) {
    return (true, 'assets/body/masks/front_shoulders_anterior.png');
  }
  if (n.contains('lateral delt') || n.contains('side delt') || n.contains('vai bên') ||
      n.contains('shoulder') || n.contains('vai')) {
    return (true, 'assets/body/masks/front_shoulders_lateral.png');
  }

  if (n.contains('lat') || n.contains('lưng rộng') || n.contains('latissimus')) {
    return (false, 'assets/body/masks/back_lats.png');
  }
  if (n.contains('trap') || n.contains('trapezius') || n.contains('thang')) {
    return (false, 'assets/body/masks/back_traps.png');
  }
  if (n.contains('tricep') || n.contains('tam đầu')) {
    return (false, 'assets/body/masks/back_triceps.png');
  }
  if (n.contains('hamstring') || n.contains('đùi sau')) {
    return (false, 'assets/body/masks/back_hamstrings.png');
  }
  if (n.contains('glute') || n.contains('gluteus') || n.contains('mông')) {
    return (false, 'assets/body/masks/back_glute.png');
  }
  if (n.contains('rear delt') || n.contains('posterior delt') || n.contains('vai sau')) {
    return (false, 'assets/body/masks/back_shoulders_posterior.png');
  }
  if (n.contains('rhomboid')) {
    return (false, 'assets/body/masks/back_rhomboids.png');
  }
  if (n.contains('teres')) {
    return (false, 'assets/body/masks/back_teres_major.png');
  }
  if (n.contains('back') || n.contains('lưng')) {
    return (false, 'assets/body/masks/back_lats.png');
  }

  return null;
}

class MuscleProgressGrid extends StatefulWidget {
  final List<MuscleProgressData> items;
  final bool isLoading;

  const MuscleProgressGrid({
    super.key,
    required this.items,
    this.isLoading = false,
  });

  @override
  State<MuscleProgressGrid> createState() => _MuscleProgressGridState();
}

class _MuscleProgressGridState extends State<MuscleProgressGrid> {
  bool _showFront = true;
  String? _expandedMuscleId;

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return Column(
        children: [
          SkeletonBox(width: double.infinity, height: 240, radius: AppTheme.radiusLg),
          const SizedBox(height: 12),
          SkeletonBox(width: double.infinity, height: 120, radius: AppTheme.radiusMd),
        ],
      );
    }

    if (widget.items.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.outlineStrong.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              PhosphorIconsBold.person,
              color: AppColors.textTertiary,
              size: 40,
            ),
            const SizedBox(height: 12),
            const Text(
              'Chưa có dữ liệu tiến độ cơ bắp',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Hoàn thành buổi tập để xem tiến độ',
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    final sorted = [...widget.items]
      ..sort((a, b) {
        if (a.isLagging != b.isLagging) return a.isLagging ? -1 : 1;
        final lvlDiff = b.level.compareTo(a.level);
        return lvlDiff != 0 ? lvlDiff : b.totalExp.compareTo(a.totalExp);
      });

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: sorted.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _BodyMapCard(
              items: widget.items,
              showFront: _showFront,
              onToggle: () => setState(() => _showFront = !_showFront),
              selectedMuscleId: _expandedMuscleId,
              selectedMuscle: _expandedMuscleId != null
                  ? sorted.firstWhere(
                      (m) => m.id == _expandedMuscleId,
                      orElse: () => sorted.first,
                    )
                  : null,
            ),
          );
        }

        final muscle = sorted[index - 1];
        final isExpanded = _expandedMuscleId == muscle.id;

        return _MuscleItemCard(
          data: muscle,
          isExpanded: isExpanded,
          onTap: () => setState(() {
            _expandedMuscleId = isExpanded ? null : muscle.id;
          }),
        );
      },
    );
  }
}

class _BodyMapCard extends StatelessWidget {
  final List<MuscleProgressData> items;
  final bool showFront;
  final VoidCallback onToggle;
  final String? selectedMuscleId;
  final MuscleProgressData? selectedMuscle;

  const _BodyMapCard({
    required this.items,
    required this.showFront,
    required this.onToggle,
    this.selectedMuscleId,
    this.selectedMuscle,
  });

  @override
  Widget build(BuildContext context) {
    final maskColors = <String, Color>{};
    for (final item in items) {
      final mapping = _muscleToMask(item.name);
      if (mapping == null) continue;
      final (isFront, path) = mapping;
      if (isFront != showFront) continue;
      final color = _tierColor(item.tier);
      final existing = maskColors[path];
      if (existing == null || color.computeLuminance() > existing.computeLuminance()) {
        maskColors[path] = color;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineStrong.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.outlineStrong.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Bản đồ cơ bắp',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        PhosphorIconsBold.arrowCounterClockwise,
                        color: AppColors.primary,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        showFront ? 'Mặt trước' : 'Mặt sau',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
              child: KeyedSubtree(
                key: ValueKey(showFront),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: 0.2,
                      child: Image.asset(
                        showFront
                            ? 'assets/body/body_front.png'
                            : 'assets/body/body_back.png',
                        height: 200,
                        fit: BoxFit.contain,
                      ),
                    ),
                    ...maskColors.entries.map((entry) {
                      final isSelected = selectedMuscle != null &&
                          _muscleToMask(selectedMuscle!.name)?.$2 == entry.key;
                      final opacity = isSelected ? 0.95 : 0.75;

                      return AnimatedOpacity(
                        opacity: opacity,
                        duration: const Duration(milliseconds: 250),
                        child: Image.asset(
                          entry.key,
                          height: 200,
                          fit: BoxFit.contain,
                          color: entry.value.withValues(alpha: opacity),
                          colorBlendMode: BlendMode.srcIn,
                        ),
                      );
                    }),
                    if (selectedMuscle != null)
                      ..._buildHighlightOverlay(selectedMuscle!, showFront),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _TierLegend(),
        ],
      ),
    );
  }

  List<Widget> _buildHighlightOverlay(
    MuscleProgressData muscle,
    bool showFront,
  ) {
    final mapping = _muscleToMask(muscle.name);
    if (mapping == null || mapping.$1 != showFront) return [];

    final glowColor = _tierColor(muscle.tier);

    return [
      Opacity(
        opacity: 0.5,
        child: Image.asset(
          mapping.$2,
          height: 200,
          fit: BoxFit.contain,
          color: glowColor,
          colorBlendMode: BlendMode.screen,
        ),
      ),
      TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.3, end: 0.8),
        duration: const Duration(milliseconds: 1500),
        curve: Curves.easeInOut,
        builder: (context, opacity, child) {
          return Opacity(
            opacity: opacity,
            child: Image.asset(
              mapping.$2,
              height: 200,
              fit: BoxFit.contain,
              color: glowColor.withValues(alpha: 0.4),
              colorBlendMode: BlendMode.screen,
            ),
          );
        },
        onEnd: () {},
      ),
    ];
  }
}

class _TierLegend extends StatelessWidget {
  const _TierLegend();

  static const _tiers = [
    ('Iron', Color(0xFF555555)),
    ('Bronze', Color(0xFFCD7F32)),
    ('Silver', Color(0xFFA8A8A8)),
    ('Gold', Color(0xFFFFCC00)),
    ('Diamond', AppColors.primary),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: _tiers.map((t) {
        final (label, color) = t;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

