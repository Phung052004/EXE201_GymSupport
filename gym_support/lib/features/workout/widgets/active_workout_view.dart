import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/exercise.dart';
import 'active_workout_exercise_card.dart';

class ActiveWorkoutView extends StatefulWidget {
  final List<Exercise> exercises;
  final String dayLabel;
  final String focus;
  final ValueChanged<String> onRemoveExercise;
  final void Function(String exerciseId, String sets, String reps)
  onUpdateExercise;
  final Future<void> Function({
    required int completedCount,
    required int completedSets,
    required int elapsedSeconds,
    required int totalExercises,
  })
  onFinishWorkout;

  const ActiveWorkoutView({
    super.key,
    required this.exercises,
    required this.dayLabel,
    required this.focus,
    required this.onRemoveExercise,
    required this.onUpdateExercise,
    required this.onFinishWorkout,
  });

  @override
  State<ActiveWorkoutView> createState() => _ActiveWorkoutViewState();
}

class _ActiveWorkoutViewState extends State<ActiveWorkoutView> {
  Timer? timer;
  int elapsedSeconds = 0;
  bool isRunning = false;
  bool isFinishing = false;
  final Set<String> completedExerciseIds = {};

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void toggleTimer() {
    if (isRunning) {
      timer?.cancel();
      setState(() {
        isRunning = false;
      });
      return;
    }

    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        elapsedSeconds++;
      });
    });

    setState(() {
      isRunning = true;
    });
  }

  void toggleComplete(String exerciseId) {
    setState(() {
      if (completedExerciseIds.contains(exerciseId)) {
        completedExerciseIds.remove(exerciseId);
      } else {
        completedExerciseIds.add(exerciseId);
      }
    });
  }

  String get formattedTime {
    final minutes = elapsedSeconds ~/ 60;
    final seconds = elapsedSeconds % 60;

    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');

    return '$mm:$ss';
  }

  double get progress {
    if (widget.exercises.isEmpty) return 0;

    return completedExerciseIds.length / widget.exercises.length;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ActiveWorkoutHeader(
            formattedTime: formattedTime,
            dayLabel: widget.dayLabel,
            focus: widget.focus,
            isRunning: isRunning,
            onToggleTimer: toggleTimer,
          ),
          const SizedBox(height: 22),
          WorkoutProgressCard(progress: progress),
          const SizedBox(height: 24),
          Text(
            '${widget.dayLabel.toUpperCase()} EXERCISES',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: widget.exercises.length,
              itemBuilder: (context, index) {
                final exercise = widget.exercises[index];

                return ActiveWorkoutExerciseCard(
                  exercise: exercise,
                  isCompleted: completedExerciseIds.contains(exercise.id),
                  onToggleComplete: () => toggleComplete(exercise.id),
                  onEdit: () => _showEditSetsReps(context, exercise),
                  onRemove: () {
                    completedExerciseIds.remove(exercise.id);
                    widget.onRemoveExercise(exercise.id);
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 22),
            child: GestureDetector(
              onTap: isFinishing ? null : _finishWorkout,
              child: Container(
                height: 56,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isFinishing) ...[
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        isFinishing ? 'Finishing...' : 'Finish Workout',
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (!isFinishing) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.check_circle_outline,
                          color: AppColors.textDark,
                          size: 20,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _finishWorkout() async {
    setState(() {
      isFinishing = true;
      isRunning = false;
    });
    timer?.cancel();

    try {
      await widget.onFinishWorkout(
        completedCount: completedExerciseIds.length,
        completedSets: _completedSets,
        elapsedSeconds: elapsedSeconds,
        totalExercises: widget.exercises.length,
      );
    } finally {
      if (mounted) {
        setState(() {
          isFinishing = false;
        });
      }
    }
  }

  int get _completedSets {
    var total = 0;
    for (final exercise in widget.exercises) {
      if (!completedExerciseIds.contains(exercise.id)) continue;
      total += int.tryParse(_parseSetsReps(exercise.setsAndReps).$1) ?? 0;
    }
    return total;
  }

  void _showEditSetsReps(BuildContext context, Exercise exercise) {
    final parsed = _parseSetsReps(exercise.setsAndReps);
    final setsController = TextEditingController(text: parsed.$1);
    final repsController = TextEditingController(text: parsed.$2);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Sets/Reps'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: setsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Sets'),
              ),
              TextField(
                controller: repsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Reps'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final sets = setsController.text.trim();
                final reps = repsController.text.trim();
                if (sets.isEmpty || reps.isEmpty) return;
                Navigator.pop(context);
                widget.onUpdateExercise(exercise.id, sets, reps);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    ).whenComplete(() {
      setsController.dispose();
      repsController.dispose();
    });
  }

  (String, String) _parseSetsReps(String raw) {
    final match = RegExp(
      r'(\d+)\s*sets?\s*x\s*(\d+)',
    ).firstMatch(raw.toLowerCase());
    if (match != null) {
      return (match.group(1) ?? '3', match.group(2) ?? '10');
    }

    final alt = RegExp(r'(\d+)x(\d+)').firstMatch(raw.toLowerCase());
    if (alt != null) {
      return (alt.group(1) ?? '3', alt.group(2) ?? '10');
    }

    return ('3', '10');
  }
}

class ActiveWorkoutHeader extends StatelessWidget {
  final String formattedTime;
  final String dayLabel;
  final String focus;
  final bool isRunning;
  final VoidCallback onToggleTimer;

  const ActiveWorkoutHeader({
    super.key,
    required this.formattedTime,
    required this.dayLabel,
    required this.focus,
    required this.isRunning,
    required this.onToggleTimer,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Active Workout',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    color: AppColors.primary,
                    size: 15,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      focus.trim().isEmpty ? dayLabel : '$dayLabel • $focus',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    color: AppColors.primary,
                    size: 15,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$formattedTime elapsed',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: onToggleTimer,
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.24),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: AppColors.textDark,
              size: 32,
            ),
          ),
        ),
      ],
    );
  }
}

class WorkoutProgressCard extends StatelessWidget {
  final double progress;

  const WorkoutProgressCard({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'PROGRESS',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.42),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                '$percent%',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
