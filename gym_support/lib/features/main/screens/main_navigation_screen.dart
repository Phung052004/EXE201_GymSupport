import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/backend_api.dart';
import '../../../core/services/session_store.dart';
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

  final Map<String, Exercise> _selectedExercises = {};
  List<Exercise> _exerciseCatalog = const [];

  late String _name;
  late String _goal;
  late String _schedule;
  late String _bmi;

  @override
  void initState() {
    super.initState();
    _name = widget.name;
    _goal = widget.goal;
    _schedule = widget.schedule;
    _bmi = widget.bmi;
    _loadExerciseCatalog();
    _loadWorkoutSession();
  }

  void _updateGoals(String goal, String schedule) {
    setState(() {
      _goal = goal;
      _schedule = schedule;
    });
  }

  Future<void> _loadExerciseCatalog() async {
    try {
      final catalog = await BackendApi.getExercises();
      if (!mounted) return;
      setState(() {
        _exerciseCatalog = catalog;
      });
    } catch (_) {
      // Keep empty catalog when backend is unavailable.
    }
  }

  Future<void> _loadWorkoutSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString(SessionStore.emailKey);
      if (email == null || email.isEmpty) return;

      final session = await BackendApi.getWorkoutSession(email);
      if (!mounted || session == null) return;

      final exercises = session['exercises'];
      if (exercises is! List) return;

      final mapped = <String, Exercise>{};
      for (final item in exercises) {
        if (item is! Map<String, dynamic>) continue;
        final exercise = _exerciseFromSession(item);
        mapped[exercise.id] = exercise;
      }

      setState(() {
        _selectedExercises
          ..clear()
          ..addAll(mapped);
      });
    } catch (_) {
      // Ignore when backend unavailable.
    }
  }

  List<Exercise> get selectedExercises {
    return _selectedExercises.values.toList();
  }

  Set<String> get selectedExerciseIds => _selectedExercises.keys.toSet();

  Exercise _exerciseFromSession(Map<String, dynamic> item) {
    final id = item['exerciseId']?.toString() ?? item['name']?.toString() ?? '';
    final name = item['name']?.toString() ?? 'Exercise';
    final muscle = item['muscleGroup']?.toString() ?? 'Unknown';
    final sets = item['sets']?.toString() ?? '3';
    final reps = item['reps']?.toString() ?? '10';
    return Exercise.fromJson({
      'id': id,
      'name': name,
      'muscleGroup': muscle,
      'setsAndReps': '$sets sets x $reps reps',
    });
  }

  void toggleExercise(String exerciseId) {
    setState(() {
      if (_selectedExercises.containsKey(exerciseId)) {
        _selectedExercises.remove(exerciseId);
        return;
      }

      final catalogExercise = _exerciseCatalog.firstWhere(
        (exercise) => exercise.id == exerciseId,
        orElse: () => Exercise.fromJson({
          'id': exerciseId,
          'name': 'Exercise',
          'muscleGroup': 'Unknown',
          'setsAndReps': '3 sets x 10 reps',
        }),
      );
      _selectedExercises[exerciseId] = catalogExercise;
    });

    _persistWorkoutSession();
  }

  void removeExercise(String exerciseId) {
    setState(() {
      _selectedExercises.remove(exerciseId);
    });

    _persistWorkoutSession();
  }

  void finishWorkout() {
    setState(() {
      _selectedExercises.clear();
      currentIndex = 0;
    });

    _completeWorkout();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Workout đã hoàn thành!')));
  }

  Future<void> _persistWorkoutSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString(SessionStore.emailKey);
      if (email == null || email.isEmpty) return;

      final payload = _selectedExercises.values
          .map(
            (exercise) => {
              'exerciseId': exercise.id,
              'name': exercise.name,
              'muscleGroup': exercise.muscleGroup,
              'setsAndReps': exercise.setsAndReps,
            },
          )
          .toList();

      await BackendApi.saveWorkoutSession(email: email, exercises: payload);
    } catch (_) {
      // Ignore sync errors for now.
    }
  }

  Future<void> _completeWorkout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString(SessionStore.emailKey);
      if (email == null || email.isEmpty) return;
      await BackendApi.completeWorkout(email: email);
    } catch (_) {
      // Ignore completion errors for now.
    }
  }

  Future<void> updateExerciseSetsReps(
    String exerciseId,
    String sets,
    String reps,
  ) async {
    final current = _selectedExercises[exerciseId];
    if (current == null) return;

    setState(() {
      _selectedExercises[exerciseId] = Exercise.fromJson({
        'id': current.id,
        'name': current.name,
        'muscleGroup': current.muscleGroup,
        'setsAndReps': '$sets sets x $reps reps',
      });
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString(SessionStore.emailKey);
      if (email == null || email.isEmpty) return;
      await BackendApi.updateWorkoutExercise(
        email: email,
        exerciseId: exerciseId,
        sets: sets,
        reps: reps,
      );
    } catch (_) {
      // Ignore update errors for now.
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(name: _name, goal: _goal, schedule: _schedule, bmi: _bmi),

      AiCoachScreen(name: _name, goal: _goal, schedule: _schedule, bmi: _bmi),

      WorkoutScreen(
        selectedExercises: selectedExercises,
        onBrowseExercises: () {
          setState(() {
            currentIndex = 3;
          });
        },
        onRemoveExercise: removeExercise,
        onUpdateExercise: updateExerciseSetsReps,
        onFinishWorkout: finishWorkout,
      ),

      ExercisesScreen(
        goal: _goal,
        schedule: _schedule,
        selectedExerciseIds: selectedExerciseIds,
        onToggleExercise: toggleExercise,
      ),

      ProfileScreen(
        name: _name,
        goal: _goal,
        schedule: _schedule,
        bmi: _bmi,
        onGoalsUpdated: _updateGoals,
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
          if (index == 2) {
            _loadWorkoutSession();
          }
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
