import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:gym_support/core/constants/app_colors.dart';
import 'package:gym_support/core/constants/app_theme.dart';

class WorkoutSummaryScreen extends StatelessWidget {
  final Map<String, dynamic> summary;

  const WorkoutSummaryScreen({super.key, required this.summary});

  String _formatDuration(dynamic raw) {
    if (raw is String && raw.contains(':')) return raw;
    final secs = int.tryParse(raw?.toString() ?? '') ?? 0;
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final planName    = summary['planName']?.toString() ?? '';
    final dayName     = summary['dayName']?.toString() ?? '';
    final duration    = _formatDuration(summary['duration'] ?? summary['durationSeconds']);
    final totalSets   = summary['totalSets']?.toString() ?? '0';
    final totalExp    = summary['totalExpGained']?.toString() ?? '0';
    final exercises   = (summary['exercises'] as List?)?.cast<Map>() ?? [];
    final muscleGains = (summary['muscleExpGains'] as List?)?.cast<Map>() ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [

            // ── Hero ──────────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 48, 20, 40),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF003D4D), Color(0xFF001820), AppColors.background],
                    stops: [0.0, 0.6, 1.0],
                  ),
                ),
                child: Column(
                  children: [
                    // Check icon with cyan glow
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: AppTheme.cyanGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.40),
                            blurRadius: 36,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: const Icon(
                        PhosphorIconsBold.check,
                        color: AppColors.textDark,
                        size: 46,
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Buổi tập hoàn thành! 💪',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    if (planName.isNotEmpty || dayName.isNotEmpty)
                      Text(
                        planName.isEmpty ? dayName : '$planName · $dayName',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            ),

            // ── Stats row ─────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  children: [
                    _StatTile(
                      icon: PhosphorIconsBold.timer,
                      iconColor: AppColors.blue,
                      value: duration,
                      label: 'Thời gian',
                    ),
                    const SizedBox(width: 10),
                    _StatTile(
                      icon: PhosphorIconsBold.repeat,
                      iconColor: AppColors.orange,
                      value: totalSets,
                      label: 'Tổng sets',
                    ),
                    const SizedBox(width: 10),
                    _StatTile(
                      icon: PhosphorIconsBold.lightning,
                      iconColor: AppColors.gold,
                      value: '+$totalExp',
                      label: 'XP',
                    ),
                  ],
                ),
              ),
            ),

            // ── Muscle Gains ──────────────────────────────────────────────────
            if (muscleGains.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                  child: Row(
                    children: [
                      const Text(
                        'Cơ bắp đã rèn',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          '${muscleGains.length}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final mg = muscleGains[i];
                    final name = mg['muscleName']?.toString() ?? mg['muscle']?.toString() ?? '—';
                    final exp = int.tryParse(mg['expGained']?.toString() ?? '') ?? 0;
                    final levelUp = mg['leveledUp'] == true;
                    return Container(
                      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(color: AppColors.outline),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              PhosphorIconsBold.barbell,
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (levelUp)
                            Container(
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.gold.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                              ),
                              child: const Text(
                                '⬆ LEVEL UP',
                                style: TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          Text(
                            '+$exp XP',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: muscleGains.length,
                ),
              ),
            ],

            // ── Exercises Done ────────────────────────────────────────────────
            if (exercises.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: const Text(
                    'Bài tập đã làm',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final ex = exercises[i];
                    final name = ex['name']?.toString() ?? '—';
                    final sets = ex['sets']?.toString() ?? '0';
                    return Container(
                      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(color: AppColors.outline),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(
                                  color: AppColors.success,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Icon(PhosphorIconsBold.checkCircle,
                              color: AppColors.success, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '$sets sets',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: exercises.length,
                ),
              ),
            ],

            // ── CTA ──────────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 40),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppTheme.cyanGradient,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: AppColors.textDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        ),
                      ),
                      child: const Text(
                        'Về trang chủ',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppColors.outline),
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
