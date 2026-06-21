import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/exercise.dart';
import '../screens/exercise_detail_screen.dart';

class ExercisePickerCard extends StatelessWidget {
  final Exercise exercise;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onAction;

  const ExercisePickerCard({
    super.key,
    required this.exercise,
    required this.actionLabel,
    required this.actionIcon,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _ExerciseImage(exercise: exercise),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            exercise.muscleGroup.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      exercise.videoUrl.isEmpty
                          ? Icons.image_rounded
                          : Icons.play_circle_fill_rounded,
                      color: AppColors.accent,
                      size: 28,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(
                      icon: Icons.fitness_center_rounded,
                      label: exercise.equipment.isEmpty
                          ? 'Equipment N/A'
                          : exercise.equipment,
                    ),
                    _InfoChip(
                      icon: Icons.speed_rounded,
                      label: exercise.difficulty.isEmpty
                          ? 'Level N/A'
                          : exercise.difficulty,
                    ),
                    _InfoChip(
                      icon: Icons.timer_rounded,
                      label:
                          '${exercise.defaultSets} x ${exercise.defaultReps}',
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => showExerciseDetailSheet(
                          context,
                          exercise,
                          onAdd: onAction,
                          actionLabel: actionLabel,
                        ),
                        icon: const Icon(Icons.visibility_rounded, size: 18),
                        label: const Text('View Detail'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onAction,
                        icon: Icon(actionIcon, size: 18),
                        label: Text(actionLabel),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showExerciseDetailSheet(
  BuildContext context,
  Exercise exercise, {
  VoidCallback? onAdd,
  String actionLabel = 'Add',
}) async {
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ExerciseDetailScreen(
        exercise: exercise,
        onAdd: onAdd,
        addLabel: actionLabel,
      ),
    ),
  );
}

Future<void> showExerciseDetailSheetLegacy(
  BuildContext context,
  Exercise exercise,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.55,
        maxChildSize: 0.96,
        builder: (context, controller) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            clipBehavior: Clip.antiAlias,
            child: ListView(
              controller: controller,
              padding: EdgeInsets.zero,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _ExerciseImage(exercise: exercise),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.1),
                              Colors.black.withValues(alpha: 0.78),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 18,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exercise.name,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _InfoChip(label: exercise.muscleGroup),
                                _InfoChip(label: exercise.difficulty),
                                _InfoChip(label: exercise.equipment),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: IconButton.filled(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black.withValues(
                              alpha: 0.48,
                            ),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MetricRow(exercise: exercise),
                      const SizedBox(height: 22),
                      _DetailSection(
                        title: 'Description',
                        text: exercise.description,
                        fallback: 'Chưa có mô tả cho bài tập này.',
                      ),
                      _DetailSection(
                        title: 'Instruction',
                        text: exercise.instruction,
                        fallback: 'Chưa có hướng dẫn thực hiện.',
                      ),
                      _DetailSection(
                        title: 'Safety Notes',
                        text: exercise.safetyNotes,
                        fallback: 'Không có lưu ý an toàn đặc biệt.',
                      ),
                      _DetailSection(
                        title: 'Common Mistakes',
                        text: exercise.commonMistakes,
                        fallback: 'Chưa có lỗi thường gặp.',
                      ),
                      _DetailSection(
                        title: 'Tips',
                        text: exercise.tips,
                        fallback: 'Chưa có mẹo tập luyện.',
                      ),
                      const SizedBox(height: 8),
                      _VideoGuide(url: exercise.videoUrl),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _ExerciseImage extends StatelessWidget {
  final Exercise exercise;

  const _ExerciseImage({required this.exercise});

  @override
  Widget build(BuildContext context) {
    if (exercise.imageUrl.isEmpty) {
      return Container(
        color: AppColors.surface2,
        child: Center(
          child: Icon(exercise.icon, color: AppColors.primary, size: 42),
        ),
      );
    }

    return Image.network(
      exercise.imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: AppColors.surface2,
        child: Center(
          child: Icon(exercise.icon, color: AppColors.primary, size: 42),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData? icon;
  final String label;

  const _InfoChip({this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final safeLabel = label.trim().isEmpty ? 'N/A' : label.trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 5),
          ],
          Text(
            safeLabel,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final Exercise exercise;

  const _MetricRow({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricTile(
            label: 'Sets',
            value: exercise.defaultSets.toString(),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetricTile(label: 'Reps', value: exercise.defaultReps),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetricTile(
            label: 'Rest',
            value: '${exercise.restTimeSeconds}s',
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;

  const _MetricTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final String text;
  final String fallback;

  const _DetailSection({
    required this.title,
    required this.text,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final content = text.trim().isEmpty ? fallback : text.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoGuide extends StatelessWidget {
  final String url;

  const _VideoGuide({required this.url});

  @override
  Widget build(BuildContext context) {
    final hasVideo = url.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(
            hasVideo
                ? Icons.play_circle_fill_rounded
                : Icons.videocam_off_rounded,
            color: hasVideo ? AppColors.accent : AppColors.textSecondary,
            size: 30,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Video Guide',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                SelectableText(
                  hasVideo ? url.trim() : 'Chưa có video hướng dẫn.',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
