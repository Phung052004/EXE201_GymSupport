import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/backend_api.dart';
import '../../../core/services/session_store.dart';
import '../widgets/muscle_progress_card.dart';

class MuscleDetailScreen extends StatefulWidget {
  final List<MuscleProgressData>? items;

  const MuscleDetailScreen({super.key, this.items});

  @override
  State<MuscleDetailScreen> createState() => _MuscleDetailScreenState();
}

class _MuscleDetailScreenState extends State<MuscleDetailScreen> {
  List<MuscleProgressData> _muscles = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMuscleProgress();
  }

  Future<void> _loadMuscleProgress() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final data = await BackendApi.getUserMuscleProgress();
      
      if (!mounted) return;

      final muscles = data
          .map((item) => MuscleProgressData(
                id: item['id'] ?? '',
                name: item['name'] ?? '',
                category: item['category'] ?? '',
                level: (item['level'] as num?)?.toInt() ?? 0,
                totalExp: (item['totalExp'] as num?)?.toInt() ?? 0,
                currentLevelExp: (item['currentLevelExp'] as num?)?.toInt() ?? 0,
                expToNextLevel:
                    (item['expToNextLevel'] as num?)?.toInt() ?? 0,
                progress: (item['progress'] as num?)?.toDouble() ?? 0.0,
                tier: item['tier'] ?? '',
                isLagging: (item['isLagging'] as bool?) ?? false,
              ))
          .toList();

      setState(() {
        _muscles = muscles;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            color: AppColors.textPrimary,
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Muscle Progress',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            color: AppColors.textPrimary,
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Muscle Progress',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error loading muscle data',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadMuscleProgress,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final byName = {
      for (final item in _muscles) _normalize(item.name): item,
    };

    MuscleProgressData? find(List<String> keys) {
      for (final key in keys) {
        final value = byName[_normalize(key)];
        if (value != null) return value;
      }
      return null;
    }

    final chest = find(['Chest', 'Pectorals', 'Nguc']);
    final shoulders = find(['Shoulders', 'Delts', 'Vai']);
    final biceps = find(['Biceps', 'Arms', 'Tay truoc']);
    final triceps = find(['Triceps', 'Tay sau']);
    final abs = find(['Abs', 'Core', 'Bung']);
    final back = find(['Back', 'Lats', 'Traps', 'Lung']);
    final glutes = find(['Glutes', 'Mong']);
    final legs = find(['Legs', 'Quads', 'Hamstrings', 'Chan']);
    final calves = find(['Calves', 'Bap chan']);

    // Front muscles
    final frontMuscles = _BodyMuscles(
      chest: chest,
      shoulders: shoulders,
      leftArm: biceps ?? triceps,
      rightArm: biceps ?? triceps,
      core: abs,
      hips: glutes,
      leftLeg: legs,
      rightLeg: legs,
      calves: calves,
    );

    // Back muscles
    final backMuscles = _BodyMuscles(
      chest: back,
      shoulders: shoulders,
      leftArm: triceps,
      rightArm: triceps,
      core: back,
      hips: glutes,
      leftLeg: legs,
      rightLeg: legs,
      calves: calves,
    );

    // Get all muscles with exp
    final allMuscles = _muscles.toList()
      ..sort((a, b) {
        // Sort by: lagging first, then by level descending, then by name
        if (a.isLagging != b.isLagging) return a.isLagging ? -1 : 1;
        if (b.level != a.level) return b.level.compareTo(a.level);
        return a.name.compareTo(b.name);
      });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          color: AppColors.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Muscle Progress',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          // 1/4: Front and Back models side by side
          Container(
            color: const Color(0xFF1D2527),
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Front model
                Column(
                  children: [
                    Text(
                      'Front',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 140,
                      height: 200,
                      child: _BodyFigure(
                        isBack: false,
                        muscles: frontMuscles,
                      ),
                    ),
                  ],
                ),
                // Back model
                Column(
                  children: [
                    Text(
                      'Back',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 140,
                      height: 200,
                      child: _BodyFigure(
                        isBack: true,
                        muscles: backMuscles,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 3/4: Muscle list
          Expanded(
            child: Container(
              color: AppColors.background,
              child: allMuscles.isEmpty
                  ? const Center(
                      child: Text(
                        'No muscle data available',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: allMuscles.length,
                      itemBuilder: (context, index) {
                        final muscle = allMuscles[index];
                        return _MuscleListItem(muscle: muscle);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  static String _normalize(String value) {
    final lower = value.toLowerCase();
    final folded = lower
        .replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
        .replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e')
        .replaceAll(RegExp(r'[ìíịỉĩ]'), 'i')
        .replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
        .replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u')
        .replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y')
        .replaceAll('đ', 'd');
    return folded.replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}

// Helper function to get tier color based on tier string
Color _getTierColor(String tier) {
  switch (tier.toLowerCase()) {
    case 'champion':
      return const Color(0xFF9C27B0);
    case 'diamond':
      return const Color(0xFF2196F3);
    case 'platinum':
      return const Color(0xFFE91E63);
    case 'gold':
      return const Color(0xFFFFC107);
    case 'silver':
      return const Color(0xFFC0C0C0);
    case 'bronze':
      return const Color(0xFFCD7F32);
    case 'iron':
    default:
      return const Color(0xFF808080);
  }
}

class _MuscleListItem extends StatelessWidget {
  final MuscleProgressData muscle;

  const _MuscleListItem({required this.muscle});

  @override
  Widget build(BuildContext context) {
    final tierColor = _getTierColor(muscle.tier);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tierColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Tier colored dot
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tierColor,
            ),
          ),
          const SizedBox(width: 10),
          // Muscle name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  muscle.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Lv ${muscle.level}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${muscle.currentLevelExp}/${muscle.expToNextLevel} XP',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Total XP
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${muscle.totalExp}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text(
                'XP',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BodyMuscles {
  final MuscleProgressData? chest;
  final MuscleProgressData? shoulders;
  final MuscleProgressData? leftArm;
  final MuscleProgressData? rightArm;
  final MuscleProgressData? core;
  final MuscleProgressData? hips;
  final MuscleProgressData? leftLeg;
  final MuscleProgressData? rightLeg;
  final MuscleProgressData? calves;

  const _BodyMuscles({
    this.chest,
    this.shoulders,
    this.leftArm,
    this.rightArm,
    this.core,
    this.hips,
    this.leftLeg,
    this.rightLeg,
    this.calves,
  });
}

class _BodyFigure extends StatelessWidget {
  final bool isBack;
  final _BodyMuscles muscles;

  const _BodyFigure({required this.isBack, required this.muscles});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            isBack ? 'assets/body/body_back.png' : 'assets/body/body_front.png',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
          ..._maskLayers(),
        ],
      ),
    );
  }

  List<Widget> _maskLayers() {
    final side = isBack ? 'back' : 'front';
    final entries = isBack
        ? <(String, MuscleProgressData?)>[
            ('back', muscles.chest),
            ('shoulders', muscles.shoulders),
            ('arms', muscles.leftArm),
            ('glutes', muscles.hips),
            ('legs', muscles.leftLeg),
            ('calves', muscles.calves),
          ]
        : <(String, MuscleProgressData?)>[
            ('chest', muscles.chest),
            ('shoulders', muscles.shoulders),
            ('arms', muscles.leftArm),
            ('core', muscles.core),
            ('glutes', muscles.hips),
            ('legs', muscles.leftLeg),
            ('calves', muscles.calves),
          ];

    return entries
        .where((entry) => entry.$2 != null && entry.$2!.totalExp > 0)
        .map(
          (entry) => IgnorePointer(
            child: Image.asset(
              'assets/body/masks/${side}_${entry.$1}.png',
              fit: BoxFit.contain,
              color: _figureColor(entry.$2)
                  .withValues(alpha: entry.$2!.isLagging ? 0.94 : 0.86),
              colorBlendMode: BlendMode.srcIn,
              filterQuality: FilterQuality.high,
            ),
          ),
        )
        .toList(growable: false);
  }
}

Color _figureColor(MuscleProgressData? data) {
  if (data == null) return const Color(0xFFCDD5D7);
  if (data.isLagging) return const Color(0xFFFF6D65);
  return Color.lerp(const Color(0xFF8DDC18), const Color(0xFFB7FF2A), 0.5) ??
      const Color(0xFFB7FF2A);
}
