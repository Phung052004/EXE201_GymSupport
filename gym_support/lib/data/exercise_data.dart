import 'package:flutter/material.dart';

import '../models/exercise.dart';

class ExerciseData {
  static const List<Exercise> exercises = [
    Exercise(
      id: 'bench_press',
      name: 'Barbell Bench Press',
      muscleGroup: 'Chest',
      setsAndReps: '4 sets x 8 reps',
      icon: Icons.fitness_center,
    ),
    Exercise(
      id: 'squat',
      name: 'Barbell Squat',
      muscleGroup: 'Legs',
      setsAndReps: '4 sets x 8 reps',
      icon: Icons.accessibility_new,
    ),
    Exercise(
      id: 'deadlift',
      name: 'Deadlift',
      muscleGroup: 'Back',
      setsAndReps: '3 sets x 5 reps',
      icon: Icons.fitness_center,
    ),
    Exercise(
      id: 'overhead_press',
      name: 'Overhead Press',
      muscleGroup: 'Shoulders',
      setsAndReps: '4 sets x 10 reps',
      icon: Icons.upload,
    ),
    Exercise(
      id: 'pull_ups',
      name: 'Pull-ups',
      muscleGroup: 'Back',
      setsAndReps: '3 sets x 10 reps',
      icon: Icons.keyboard_arrow_up,
    ),
    Exercise(
      id: 'bicep_curls',
      name: 'Bicep Curls',
      muscleGroup: 'Arms',
      setsAndReps: '3 sets x 12 reps',
      icon: Icons.sports_gymnastics,
    ),
    Exercise(
      id: 'leg_press',
      name: 'Leg Press',
      muscleGroup: 'Legs',
      setsAndReps: '4 sets x 12 reps',
      icon: Icons.airline_seat_legroom_extra,
    ),
    Exercise(
      id: 'incline_dumbbell_press',
      name: 'Incline Dumbbell Press',
      muscleGroup: 'Chest',
      setsAndReps: '3 sets x 10 reps',
      icon: Icons.fitness_center,
    ),
  ];
}
