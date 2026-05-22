import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/exercise_data.dart';
import '../../../models/exercise.dart';
import '../../ai_coach/screens/ai_coach_screen.dart';
import '../../exercises/screens/exercises_screen.dart';
import '../../home/screens/home_screen.dart';
import '../../home/widgets/app_bottom_nav_bar.dart';
import '../../profile/screens/profile_screen.dart';
import '../../workout/screens/workout_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final String name;
  final String goal;
  final String schedule;
  final String bmi;

  const MainNavigationScreen({
    super.key,
    required this.name,
    required this.goal,
    required this.schedule,
    required this.bmi,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int currentIndex = 0;

  final Set<String> selectedExerciseIds = {'bench_press', 'squat'};

  List<Exercise> get selectedExercises {
    return ExerciseData.exercises.where((exercise) {
      return selectedExerciseIds.contains(exercise.id);
    }).toList();
  }

  void toggleExercise(String exerciseId) {
    setState(() {
      if (selectedExerciseIds.contains(exerciseId)) {
        selectedExerciseIds.remove(exerciseId);
      } else {
        selectedExerciseIds.add(exerciseId);
      }
    });
  }

  void removeExercise(String exerciseId) {
    setState(() {
      selectedExerciseIds.remove(exerciseId);
    });
  }

  void finishWorkout() {
    setState(() {
      selectedExerciseIds.clear();
      currentIndex = 0;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Workout đã hoàn thành!')));
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        name: widget.name,
        goal: widget.goal,
        schedule: widget.schedule,
        bmi: widget.bmi,
      ),

      AiCoachScreen(
        name: widget.name,
        goal: widget.goal,
        schedule: widget.schedule,
        bmi: widget.bmi,
      ),

      WorkoutScreen(
        selectedExercises: selectedExercises,
        onBrowseExercises: () {
          setState(() {
            currentIndex = 3;
          });
        },
        onRemoveExercise: removeExercise,
        onFinishWorkout: finishWorkout,
      ),

      ExercisesScreen(
        goal: widget.goal,
        schedule: widget.schedule,
        selectedExerciseIds: selectedExerciseIds,
        onToggleExercise: toggleExercise,
      ),

      ProfileScreen(
        name: widget.name,
        goal: widget.goal,
        schedule: widget.schedule,
        bmi: widget.bmi,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: IndexedStack(index: currentIndex, children: pages),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
      ),
    );
  }
}

class PlaceholderTabScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const PlaceholderTabScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary, size: 36),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
