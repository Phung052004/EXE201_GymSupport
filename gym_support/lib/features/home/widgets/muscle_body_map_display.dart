import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/app_colors.dart';
import 'muscle_progress_card.dart';
import 'muscle_detail_modal.dart';

class MuscleBodyMapDisplay extends StatefulWidget {
  final List<MuscleProgressData> items;
  final bool isLoading;

  const MuscleBodyMapDisplay({
    required this.items,
    this.isLoading = false,
  });

  @override
  State<MuscleBodyMapDisplay> createState() => _MuscleBodyMapDisplayState();
}

class _MuscleBodyMapDisplayState extends State<MuscleBodyMapDisplay> {
  bool _showFront = true;
  String? _selectedMuscleId;

  Map<String, MuscleProgressData> _buildMuscleMap() {
    return {for (final item in widget.items) item.id: item};
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
    if (n.contains('anterior delt') ||
        n.contains('front delt') ||
        n.contains('vai trước')) {
      return (true, 'assets/body/masks/front_shoulders_anterior.png');
    }
    if (n.contains('lateral delt') ||
        n.contains('side delt') ||
        n.contains('vai bên') ||
        n.contains('shoulder') ||
        n.contains('vai')) {
      return (true, 'assets/body/masks/front_shoulders_lateral.png');
    }

    if (n.contains('lat') ||
        n.contains('lưng rộng') ||
        n.contains('latissimus')) {
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
    if (n.contains('rear delt') ||
        n.contains('posterior delt') ||
        n.contains('vai sau')) {
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

    final muscleMap = _buildMuscleMap();
    final maskColors = <String, MuscleProgressData>{};

    for (final item in widget.items) {
      final mapping = _muscleToMask(item.name);
      if (mapping == null) continue;
      final (isFront, path) = mapping;
      if (isFront != _showFront) continue;
      maskColors[path] = item;
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
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Bản đồ cơ bắp',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _showFront = !_showFront),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
                        _showFront ? 'Mặt trước' : 'Mặt sau',
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
          // Body figure with interactive muscle selection
          SizedBox(
            height: 280,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: anim,
                child: child,
              ),
              child: KeyedSubtree(
                key: ValueKey(_showFront),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Base silhouette
                    Opacity(
                      opacity: 0.15,
                      child: Image.asset(
                        _showFront
                            ? 'assets/body/body_front.png'
                            : 'assets/body/body_back.png',
                        height: 280,
                        fit: BoxFit.contain,
                      ),
                    ),
                    // Tier-colored muscle masks
                    ...maskColors.entries.map((entry) {
                      final muscle = entry.value;
                      final tierColor = _getTierColor(muscle.tier);
                      final isSelected = _selectedMuscleId == muscle.id;

                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedMuscleId = muscle.id);
                          _showMuscleDetail(muscle);
                        },
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: AnimatedOpacity(
                            opacity: isSelected ? 0.95 : 0.7,
                            duration: const Duration(milliseconds: 200),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(100),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: tierColor
                                              .withValues(alpha: 0.4),
                                          blurRadius: 12,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Image.asset(
                                entry.key,
                                height: 280,
                                fit: BoxFit.contain,
                                color: tierColor.withValues(
                                  alpha: isSelected ? 0.9 : 0.65,
                                ),
                                colorBlendMode: BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    // Glow effect on selected muscle
                    if (_selectedMuscleId != null && muscleMap.containsKey(_selectedMuscleId))
                      ..._buildGlowEffect(
                        muscleMap[_selectedMuscleId]!,
                        _getTierColor(muscleMap[_selectedMuscleId]!.tier),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Tier legend
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              _TierLegendItem('Iron', const Color(0xFF555555)),
              _TierLegendItem('Bronze', const Color(0xFFCD7F32)),
              _TierLegendItem('Silver', const Color(0xFFA8A8A8)),
              _TierLegendItem('Gold', const Color(0xFFFFCC00)),
              _TierLegendItem('Diamond', const Color(0xFF2196F3)),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGlowEffect(MuscleProgressData muscle, Color glowColor) {
    final mapping = _muscleToMask(muscle.name);
    if (mapping == null || mapping.$1 != _showFront) return [];

    return [
      Opacity(
        opacity: 0.4,
        child: Image.asset(
          mapping.$2,
          height: 280,
          fit: BoxFit.contain,
          color: glowColor,
          colorBlendMode: BlendMode.screen,
        ),
      ),
      TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.2, end: 0.6),
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeInOut,
        builder: (context, opacity, child) {
          return Opacity(
            opacity: opacity,
            child: Image.asset(
              mapping.$2,
              height: 280,
              fit: BoxFit.contain,
              color: glowColor.withValues(alpha: 0.3),
              colorBlendMode: BlendMode.screen,
            ),
          );
        },
        onEnd: () {},
      ),
    ];
  }
}

class _TierLegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const _TierLegendItem(this.label, this.color);

  @override
  Widget build(BuildContext context) {
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
                color: color.withValues(alpha: 0.4),
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
  }
}
