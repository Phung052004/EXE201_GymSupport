import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/constants/app_theme.dart';

class PopularExercisesSection extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final bool isLoading;

  const PopularExercisesSection({
    super.key,
    required this.items,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        height: 172,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, __) => const SkeletonBox(width: 130, height: 172, radius: 16),
        ),
      );
    }

    if (items.isEmpty) {
      return Container(
        height: 80,
        alignment: Alignment.center,
        child: const Text(
          'Chưa có dữ liệu',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      );
    }

    return SizedBox(
      height: 172,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => _ExerciseCard(item: items[i]),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _ExerciseCard({required this.item});

  String _muscleNetworkUrl(String muscle) => AppImages.muscleUrl(muscle);

  @override
  Widget build(BuildContext context) {
    final name = item['exerciseName']?.toString() ??
        item['name']?.toString() ??
        'Exercise';
    final count = item['sessionCount'] ?? item['count'] ?? item['weekCount'] ?? 0;
    final imageUrl = item['imageUrl']?.toString() ?? '';
    final muscle = item['muscleName']?.toString() ?? item['muscleGroup']?.toString() ?? '';

    return Container(
      width: 130,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          SizedBox(
            height: 100,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: imageUrl.isNotEmpty
                      ? imageUrl
                      : _muscleNetworkUrl(muscle),
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: AppColors.surface2),
                  errorWidget: (_, __, ___) => _NetworkFallback(url: _muscleNetworkUrl(muscle)),
                ),
                // Count chip top-right
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.80),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      '$count×',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                  if (muscle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        muscle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NetworkFallback extends StatelessWidget {
  final String url;
  const _NetworkFallback({required this.url});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: AppImages.workoutBanner,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(color: AppColors.surface2),
          errorWidget: (_, __, ___) => Container(color: AppColors.surface2),
        ),
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x44000000), Color(0x88000000)],
            ),
          ),
        ),
      ],
    );
  }
}
