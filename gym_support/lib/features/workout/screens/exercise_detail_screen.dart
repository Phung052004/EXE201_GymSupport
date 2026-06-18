import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/exercise.dart';

class ExerciseDetailScreen extends StatelessWidget {
  final Exercise exercise;
  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          backgroundColor: AppColors.ink,
          foregroundColor: Colors.white,
          leading: Padding(
            padding: const EdgeInsets.all(8),
            child: IconButton.filled(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded),
              style: IconButton.styleFrom(backgroundColor: Colors.black45),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(background: _ExerciseHero(exercise)),
        ),
        SliverToBoxAdapter(
          child: Transform.translate(
            offset: const Offset(0, -22),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _Metric(
                          'SETS',
                          '${exercise.defaultSets}',
                          Icons.layers_rounded,
                          AppColors.violet,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _Metric(
                          'REPS',
                          exercise.defaultReps,
                          Icons.repeat_rounded,
                          AppColors.blue,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _Metric(
                          'REST',
                          '${exercise.restTimeSeconds}s',
                          Icons.timer_rounded,
                          AppColors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _Detail(
                    'Description',
                    exercise.description,
                    'Chưa có mô tả cho bài tập này.',
                    Icons.notes_rounded,
                    AppColors.blue,
                  ),
                  _Detail(
                    'How to perform',
                    exercise.instruction,
                    'Chưa có hướng dẫn thực hiện.',
                    Icons.format_list_numbered_rounded,
                    AppColors.violet,
                  ),
                  _Detail(
                    'Safety notes',
                    exercise.safetyNotes,
                    'Không có lưu ý an toàn đặc biệt.',
                    Icons.health_and_safety_rounded,
                    AppColors.orange,
                  ),
                  _Detail(
                    'Common mistakes',
                    exercise.commonMistakes,
                    'Chưa có lỗi thường gặp.',
                    Icons.warning_amber_rounded,
                    const Color(0xFFEF5A6F),
                  ),
                  _Detail(
                    'Coach tips',
                    exercise.tips,
                    'Chưa có mẹo tập luyện.',
                    Icons.lightbulb_rounded,
                    AppColors.primaryDark,
                  ),
                  _Video(exercise.videoUrl),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _ExerciseHero extends StatelessWidget {
  final Exercise exercise;
  const _ExerciseHero(this.exercise);
  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      exercise.imageUrl.isEmpty
          ? _fallback()
          : Image.network(
              exercise.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallback(),
            ),
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Color(0xEE11191F)],
          ),
        ),
      ),
      Positioned(
        left: 20,
        right: 20,
        bottom: 40,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                exercise.muscleGroup.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              exercise.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                height: 1.05,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _Chip(
                  Icons.fitness_center_rounded,
                  exercise.equipment.isEmpty
                      ? 'No equipment'
                      : exercise.equipment,
                ),
                _Chip(
                  Icons.speed_rounded,
                  exercise.difficulty.isEmpty
                      ? 'All levels'
                      : exercise.difficulty,
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );
  Widget _fallback() => Container(
    color: AppColors.ink,
    child: Icon(exercise.icon, size: 84, color: AppColors.primary),
  );
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip(this.icon, this.label);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: Colors.white24),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _Metric extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _Metric(this.label, this.value, this.icon, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: AppColors.ink.withValues(alpha: .06),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: color),
        ),
        const SizedBox(height: 9),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _Detail extends StatelessWidget {
  final String title, text, fallback;
  final IconData icon;
  final Color color;
  const _Detail(this.title, this.text, this.fallback, this.icon, this.color);
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.outline),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          text.trim().isEmpty ? fallback : text.trim(),
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.55,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

class _Video extends StatelessWidget {
  final String url;
  const _Video(this.url);
  @override
  Widget build(BuildContext context) {
    final enabled = url.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.ink, Color(0xFF293742)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: enabled ? AppColors.primary : Colors.white12,
              shape: BoxShape.circle,
            ),
            child: Icon(
              enabled ? Icons.play_arrow_rounded : Icons.videocam_off_rounded,
              color: enabled ? AppColors.ink : Colors.white54,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Video guide',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  enabled
                      ? 'Watch the movement before your first set'
                      : 'Chưa có video hướng dẫn.',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
