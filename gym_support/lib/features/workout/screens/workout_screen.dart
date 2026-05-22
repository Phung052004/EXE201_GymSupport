import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/exercise.dart';
import '../widgets/active_workout_view.dart';
import '../widgets/empty_workout_view.dart';
import '../widgets/perfect_workout_dialog.dart';

class WorkoutScreen extends StatelessWidget {
  final List<Exercise> selectedExercises;
  final VoidCallback onBrowseExercises;
  final ValueChanged<String> onRemoveExercise;
  final VoidCallback onFinishWorkout;

  const WorkoutScreen({
    super.key,
    required this.selectedExercises,
    required this.onBrowseExercises,
    required this.onRemoveExercise,
    required this.onFinishWorkout,
  });

  void showPerfectWorkoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (context) {
        return PerfectWorkoutDialog(
          exerciseCount: selectedExercises.length,
          onGoHome: () {
            Navigator.pop(context);
            onFinishWorkout();
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
            ? EmptyWorkoutView(onBrowseExercises: onBrowseExercises)
            : ActiveWorkoutView(
                exercises: selectedExercises,
                onRemoveExercise: onRemoveExercise,
                onFinishWorkout: () {
                  showPerfectWorkoutDialog(context);
                },
              ),
      ),
    );
  }
}
