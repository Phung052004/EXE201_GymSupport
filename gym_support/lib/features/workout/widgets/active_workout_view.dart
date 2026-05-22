import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/exercise.dart';
import 'active_workout_exercise_card.dart';

class ActiveWorkoutView extends StatefulWidget {
  final List<Exercise> exercises;
  final ValueChanged<String> onRemoveExercise;
  final VoidCallback onFinishWorkout;

  const ActiveWorkoutView({
    super.key,
    required this.exercises,
    required this.onRemoveExercise,
    required this.onFinishWorkout,
  });

  @override
  State<ActiveWorkoutView> createState() => _ActiveWorkoutViewState();
}

class _ActiveWorkoutViewState extends State<ActiveWorkoutView> {
  Timer? timer;
  int elapsedSeconds = 0;
  bool isRunning = false;
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
            isRunning: isRunning,
            onToggleTimer: toggleTimer,
          ),
          const SizedBox(height: 22),
          WorkoutProgressCard(progress: progress),
          const SizedBox(height: 24),
          const Text(
            "TODAY'S EXERCISES",
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
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
              onTap: widget.onFinishWorkout,
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
                child: const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Finish Workout',
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.check_circle_outline,
                        color: AppColors.textDark,
                        size: 20,
                      ),
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
}

class ActiveWorkoutHeader extends StatelessWidget {
  final String formattedTime;
  final bool isRunning;
  final VoidCallback onToggleTimer;

  const ActiveWorkoutHeader({
    super.key,
    required this.formattedTime,
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
