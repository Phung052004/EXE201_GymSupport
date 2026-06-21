import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

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
      return const SizedBox(
        height: 174,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.outline),
        ),
        child: const Text(
          'Hoàn thành một buổi tập để xem bài tập nổi bật trong tuần.',
          style: TextStyle(
            color: AppColors.textSecondary,
            height: 1.45,
            fontSize: 13,
          ),
        ),
      );
    }

    return SizedBox(
      height: 184,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return _PopularExerciseCard(item: item, rank: index + 1);
        },
      ),
    );
  }
}

class _PopularExerciseCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final int rank;

  const _PopularExerciseCard({required this.item, required this.rank});

  @override
  Widget build(BuildContext context) {
    final imageUrl = item['imageUrl']?.toString() ?? '';
    final count = int.tryParse(item['workoutCount']?.toString() ?? '') ?? 0;

    return Container(
      width: 190,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .16),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (imageUrl.isNotEmpty)
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _fallback(),
                  )
                else
                  _fallback(),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xB8000000)],
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: rank == 1
                          ? AppColors.primary
                          : Colors.black.withValues(alpha: .62),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '#$rank',
                      style: TextStyle(
                        color: rank == 1 ? AppColors.textDark : Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 10,
                  child: Text(
                    item['name']?.toString() ?? 'Exercise',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.repeat_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  '$count lượt tập tuần này',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color: const Color(0xFF30363B),
      alignment: Alignment.center,
      child: Text(
        '${item['name'] ?? 'Exercise'}',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
