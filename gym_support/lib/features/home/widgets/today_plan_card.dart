import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/constants/app_theme.dart';

class TodayPlanCard extends StatelessWidget {
  final VoidCallback onBuildRoutine;
  final VoidCallback onOpenWorkout;
  final Map<String, dynamic>? workout;
  final bool isLoading;

  const TodayPlanCard({
    super.key,
    required this.onBuildRoutine,
    required this.onOpenWorkout,
    this.workout,
    this.isLoading = false,
  });

  List<Map<String, dynamic>> get _exercises {
    final plans = workout?['workoutPlan'];
    if (plans is! List || plans.isEmpty || plans.first is! Map) return const [];
    final day = Map<String, dynamic>.from(plans.first as Map);
    final raw = day['exercises'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Map<String, dynamic>? get _selectedDay {
    final plans = workout?['workoutPlan'];
    if (plans is! List || plans.isEmpty || plans.first is! Map) return null;
    return Map<String, dynamic>.from(plans.first as Map);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Column(
        children: [
          SkeletonBox(width: double.infinity, height: 160, radius: AppTheme.radiusLg),
          const SizedBox(height: 10),
          SkeletonBox(width: double.infinity, height: 56, radius: AppTheme.radiusMd),
        ],
      );
    }

    if (workout == null || _exercises.isEmpty) {
      return _buildEmpty(context);
    }

    return _buildPlan(context);
  }

  Widget _buildEmpty(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      child: Stack(
        children: [
          // Background image
          SizedBox(
            width: double.infinity,
            height: 240,
            child: CachedNetworkImage(
              imageUrl: AppImages.workoutBanner,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: AppColors.surface2),
              errorWidget: (_, __, ___) => Image.asset(
                AppImages.workoutBannerLocal, fit: BoxFit.cover),
            ),
          ),
          // Dark overlay
          Container(
            width: double.infinity,
            height: 240,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x88001820), Color(0xEE003D4D)],
              ),
            ),
          ),
          // Content
          Container(
            width: double.infinity,
            height: 240,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.20),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                  ),
                  child: const Icon(
                    PhosphorIconsBold.barbell,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Chưa có lịch tập hôm nay',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tạo kế hoạch để bắt đầu theo dõi tiến trình',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppTheme.cyanGradient,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: ElevatedButton(
                      onPressed: onBuildRoutine,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: AppColors.textDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        ),
                      ),
                      child: const Text(
                        'Tạo lịch tập ngay',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlan(BuildContext context) {
    final day = _selectedDay!;
    final exercises = _exercises;
    final focus = day['focus']?.toString() ?? '';
    final dayLabel = day['day']?.toString() ?? 'Hôm nay';

    return Column(
      children: [
        // Hero card — dark teal gradient with cyan glow border
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: AppTheme.heroGradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Glow circle decoration
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            dayLabel,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: onOpenWorkout,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              PhosphorIconsBold.play,
                              color: AppColors.textDark,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      focus.isEmpty ? 'Workout hôm nay' : focus,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(PhosphorIconsBold.barbell, color: AppColors.textSecondary, size: 13),
                        const SizedBox(width: 4),
                        Text(
                          '${exercises.length} bài tập',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Exercise list (first 3)
        ...exercises.take(3).map((ex) => _ExerciseRow(exercise: ex)),
        if (exercises.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 4),
            child: Center(
              child: Text(
                '+${exercises.length - 3} bài tập khác',
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        const SizedBox(height: 6),
        // Start button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppTheme.cyanGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: ElevatedButton(
              onPressed: onOpenWorkout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: AppColors.textDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(PhosphorIconsBold.play, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Bắt đầu Workout',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  final Map<String, dynamic> exercise;
  const _ExerciseRow({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final name = exercise['name']?.toString() ?? 'Exercise';
    final sets = exercise['sets']?.toString() ?? '3';
    final reps = exercise['reps']?.toString() ?? '10';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              PhosphorIconsBold.barbell,
              color: AppColors.primary,
              size: 17,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$sets×$reps',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
