import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_theme.dart';

// ─── Data model ───────────────────────────────────────────────────────────────

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

// ─── Tier colors ─────────────────────────────────────────────────────────────

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
    default:
      return const Color(0xFF555555); // Iron
  }
}

// ─── Muscle → mask file mapping ──────────────────────────────────────────────

/// Returns (isFront, assetPath) for a given muscle name.
/// Returns null if no mask is available.
(bool isFront, String path)? _muscleToMask(String name) {
  final n = name.toLowerCase().trim();

  // Front muscles
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

  // Back muscles
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

// ─── Main grid widget ─────────────────────────────────────────────────────────

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

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return Column(
        children: [
          SkeletonBox(width: double.infinity, height: 220, radius: AppTheme.radiusLg),
          const SizedBox(height: 10),
          SkeletonBox(width: double.infinity, height: 72, radius: AppTheme.radiusMd),
          const SizedBox(height: 8),
          SkeletonBox(width: double.infinity, height: 72, radius: AppTheme.radiusMd),
        ],
      );
    }

    if (widget.items.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        decoration: AppTheme.cardDecoration(),
        child: const Center(
          child: Column(
            children: [
              Icon(PhosphorIconsBold.person, color: AppColors.textTertiary, size: 36),
              SizedBox(height: 10),
              Text(
                'Chưa có dữ liệu tiến độ cơ bắp',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Hoàn thành buổi tập để xem tiến độ',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    // Show top 6 muscles; sort by level desc then totalExp desc
    final sorted = [...widget.items]
      ..sort((a, b) {
        final lvlDiff = b.level.compareTo(a.level);
        return lvlDiff != 0 ? lvlDiff : b.totalExp.compareTo(a.totalExp);
      });
    final topItems = sorted.take(6).toList();

    return Column(
      children: [
        // Body map
        _BodyMapCard(
          items: widget.items,
          showFront: _showFront,
          onToggle: () => setState(() => _showFront = !_showFront),
        ),
        const SizedBox(height: 12),
        // Top muscles list
        ...topItems.asMap().entries.map((e) => _MuscleProgressItem(
              data: e.value,
              index: e.key,
            )),
        if (widget.items.length > 6)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '+${widget.items.length - 6} nhóm cơ khác',
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}

// ─── Body map card ────────────────────────────────────────────────────────────

class _BodyMapCard extends StatelessWidget {
  final List<MuscleProgressData> items;
  final bool showFront;
  final VoidCallback onToggle;

  const _BodyMapCard({
    required this.items,
    required this.showFront,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    // Build a map of: assetPath → highest tierColor among muscles that use it
    final maskColors = <String, Color>{};
    for (final item in items) {
      final mapping = _muscleToMask(item.name);
      if (mapping == null) continue;
      final (isFront, path) = mapping;
      if (isFront != showFront) continue;
      final color = _tierColor(item.tier);
      // Keep higher tier color (use luminance as proxy - brighter = higher tier)
      final existing = maskColors[path];
      if (existing == null || color.computeLuminance() > existing.computeLuminance()) {
        maskColors[path] = color;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(radius: AppTheme.radiusLg),
      child: Column(
        children: [
          // Header row
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Bản đồ cơ bắp',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              // Toggle button
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: AppColors.outlineStrong),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        PhosphorIconsBold.arrowCounterClockwise,
                        color: AppColors.primary,
                        size: 13,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        showFront ? 'Mặt trước' : 'Mặt sau',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Body figure
          SizedBox(
            height: 180,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
              child: KeyedSubtree(
                key: ValueKey(showFront),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Base silhouette (dimmed)
                    Opacity(
                      opacity: 0.25,
                      child: Image.asset(
                        showFront
                            ? 'assets/body/body_front.png'
                            : 'assets/body/body_back.png',
                        height: 180,
                        fit: BoxFit.contain,
                      ),
                    ),
                    // Colored muscle masks
                    ...maskColors.entries.map((entry) => Image.asset(
                          entry.key,
                          height: 180,
                          fit: BoxFit.contain,
                          color: entry.value.withValues(alpha: 0.85),
                          colorBlendMode: BlendMode.srcIn,
                        )),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Tier legend
          _TierLegend(),
        ],
      ),
    );
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _tiers.map((t) {
        final (label, color) = t;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─── Individual muscle row ────────────────────────────────────────────────────

class _MuscleProgressItem extends StatelessWidget {
  final MuscleProgressData data;
  final int index;

  const _MuscleProgressItem({required this.data, required this.index});

  @override
  Widget build(BuildContext context) {
    final tc = _tierColor(data.tier);
    final mapping = _muscleToMask(data.name);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: AppTheme.cardDecoration(),
      child: Row(
        children: [
          // Muscle icon / mask thumbnail
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: data.isLagging
                  ? AppColors.danger.withValues(alpha: 0.12)
                  : tc.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: mapping != null
                ? Padding(
                    padding: const EdgeInsets.all(6),
                    child: Image.asset(
                      mapping.$2,
                      color: tc,
                      colorBlendMode: BlendMode.srcIn,
                      fit: BoxFit.contain,
                    ),
                  )
                : Icon(
                    PhosphorIconsBold.barbell,
                    color: data.isLagging ? AppColors.danger : tc,
                    size: 20,
                  ),
          ),
          const SizedBox(width: 12),
          // Name + progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        data.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (data.isLagging)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Text(
                          'Yếu',
                          style: TextStyle(color: AppColors.danger, fontSize: 9, fontWeight: FontWeight.w800),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: data.progress.clamp(0.0, 1.0),
                          minHeight: 4,
                          backgroundColor: AppColors.outline,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            data.isLagging ? AppColors.danger : tc,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${data.currentLevelExp}/${data.expToNextLevel} XP',
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Level badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: tc.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: tc.withValues(alpha: 0.3)),
            ),
            child: Text(
              'Lv ${data.level}',
              style: TextStyle(
                color: tc,
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
