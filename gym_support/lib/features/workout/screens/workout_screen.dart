import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/exercise.dart';
import '../widgets/active_workout_view.dart';
import '../widgets/empty_workout_view.dart';
import '../widgets/perfect_workout_dialog.dart';

class WorkoutScreen extends StatelessWidget {
  final List<Exercise> selectedExercises;
  final String dayLabel;
  final String focus;
  final VoidCallback onBuildRoutine;
  final ValueChanged<String> onRemoveExercise;
  final void Function(String exerciseId, String sets, String reps)
  onUpdateExercise;
  final Future<Map<String, dynamic>> Function({
    required int completedCount,
    required int completedSets,
    required int elapsedSeconds,
    required int totalExercises,
  })
  onFinishWorkout;
  final VoidCallback onGoHomeAfterFinish;

  const WorkoutScreen({
    super.key,
    required this.selectedExercises,
    required this.dayLabel,
    required this.focus,
    required this.onBuildRoutine,
    required this.onRemoveExercise,
    required this.onUpdateExercise,
    required this.onFinishWorkout,
    required this.onGoHomeAfterFinish,
  });

  void showPerfectWorkoutDialog(
    BuildContext context,
    Map<String, dynamic> result,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (context) {
        return PerfectWorkoutDialog(
          result: result,
          onGoHome: () {
            Navigator.pop(context);
            onGoHomeAfterFinish();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: AppColors.background,
        child: selectedExercises.isEmpty
            ? EmptyWorkoutView(onBuildRoutine: onBuildRoutine)
            : ActiveWorkoutView(
                exercises: selectedExercises,
                dayLabel: dayLabel,
                focus: focus,
                onRemoveExercise: onRemoveExercise,
                onUpdateExercise: onUpdateExercise,
                onFinishWorkout:
                    ({
                      required completedCount,
                      required completedSets,
                      required elapsedSeconds,
                      required totalExercises,
                    }) async {
                      final result = await onFinishWorkout(
                        completedCount: completedCount,
                        completedSets: completedSets,
                        elapsedSeconds: elapsedSeconds,
                        totalExercises: totalExercises,
                      );
                      if (!context.mounted) return;
                      showPerfectWorkoutDialog(context, result);
                    },
              ),
      ),
    );
  }
}
