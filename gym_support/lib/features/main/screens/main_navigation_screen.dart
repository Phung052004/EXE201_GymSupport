import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/backend_api.dart';
import '../../../core/services/session_store.dart';
import '../../../models/exercise.dart';
import '../../ai_coach/screens/ai_coach_screen.dart';
import '../../ai_coach/screens/generate_plan_screen.dart';
import '../../home/screens/build_routine_screen.dart';
import '../../home/screens/home_screen.dart';
import '../../home/widgets/app_bottom_nav_bar.dart';
import '../../profile/screens/profile_screen.dart';
import '../../workout/screens/today_workout_screen.dart';

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
  int _homeRefreshSeed = 0;

  final Map<String, Exercise> _selectedExercises = {};

  late String _name;
  late String _goal;
  late String _schedule;
  late String _bmi;
  String _workoutDayLabel = 'Today';
  String _workoutFocus = '';

  @override
  void initState() {
    super.initState();
    _name = widget.name;
    _goal = widget.goal;
    _schedule = widget.schedule;
    _bmi = widget.bmi;
    _loadWorkoutSession();
  }

  void _updateGoals(String goal, String schedule) {
    setState(() {
      _goal = goal;
      _schedule = schedule;
    });
  }

  void _updateBmi(String bmi) {
    setState(() {
      _bmi = bmi;
    });
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
        _workoutDayLabel = session['day']?.toString() ?? 'Today';
        _workoutFocus = session['focus']?.toString() ?? '';
      });
    } catch (_) {
      // Ignore when backend unavailable.
    }
  }

  List<Exercise> get selectedExercises {
    return _selectedExercises.values.toList();
  }

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

  void removeExercise(String exerciseId) {
    setState(() {
      _selectedExercises.remove(exerciseId);
    });

    _persistWorkoutSession();
  }

  Future<void> _openBuildRoutine() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BuildRoutineScreen(goal: _goal, schedule: _schedule),
      ),
    );

    if (!mounted || created != true) return;
    await _loadWorkoutSession();
    if (!mounted) return;
    setState(() {
      currentIndex = 3;
      _homeRefreshSeed++;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Routine đã được chuyển sang Workout')),
    );
  }

  void finishWorkoutGoHome() {
    setState(() {
      _selectedExercises.clear();
      currentIndex = 0;
      _homeRefreshSeed++;
    });

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

  Future<Map<String, dynamic>> _completeWorkout({
    required int completedCount,
    required int completedSets,
    required int elapsedSeconds,
    required int totalExercises,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString(SessionStore.emailKey);
      if (email == null || email.isEmpty) {
        return _finishSummary(
          completedCount: completedCount,
          completedSets: completedSets,
          elapsedSeconds: elapsedSeconds,
          totalExercises: totalExercises,
        );
      }
      final backendResult = await BackendApi.completeWorkout(email: email);
      return _finishSummary(
        completedCount: completedCount,
        completedSets: completedSets,
        elapsedSeconds: elapsedSeconds,
        totalExercises: totalExercises,
        backendResult: backendResult,
      );
    } catch (_) {
      return _finishSummary(
        completedCount: completedCount,
        completedSets: completedSets,
        elapsedSeconds: elapsedSeconds,
        totalExercises: totalExercises,
      );
    }
  }

  Map<String, dynamic> _finishSummary({
    required int completedCount,
    required int completedSets,
    required int elapsedSeconds,
    required int totalExercises,
    Map<String, dynamic>? backendResult,
  }) {
    final backendSeconds = backendResult?['totalDurationSeconds'];
    final durationSeconds = elapsedSeconds > 0
        ? elapsedSeconds
        : int.tryParse(backendSeconds?.toString() ?? '') ?? 0;
    final backendSets = int.tryParse(
      backendResult?['totalSets']?.toString() ?? '',
    );
    final backendExp = int.tryParse(
      backendResult?['totalExpGained']?.toString() ?? '',
    );
    final muscleExpGains = backendResult?['muscleExpGains'] is List
        ? backendResult!['muscleExpGains'] as List
        : const [];

    if (mounted) {
      setState(() {
        _selectedExercises.clear();
        _homeRefreshSeed++;
      });
    }

    return {
      'day': _workoutDayLabel,
      'focus': _workoutFocus,
      'completedCount': completedCount,
      'totalExercises': totalExercises,
      'durationSeconds': durationSeconds,
      'totalSets': (backendSets ?? 0) > 0 ? backendSets : completedSets,
      'totalExpGained': backendExp ?? 0,
      'muscleExpGains': muscleExpGains,
    };
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
      HomeScreen(
        name: _name,
        goal: _goal,
        schedule: _schedule,
        bmi: _bmi,
        refreshSeed: _homeRefreshSeed,
        onBuildRoutine: _openBuildRoutine,
        onOpenWorkout: () => setState(() => currentIndex = 3),
      ),

      AiCoachScreen(name: _name, goal: _goal, schedule: _schedule, bmi: _bmi),

      const GeneratePlanScreen(),

      const TodayWorkoutScreen(),

      BuildRoutineScreen(
        goal: _goal,
        schedule: _schedule,
        onRoutineSaved: () async {
          await _loadWorkoutSession();
          if (!context.mounted) return;
          setState(() {
            currentIndex = 3;
            _homeRefreshSeed++;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Routine đã được chuyển sang Workout'),
            ),
          );
        },
      ),

      ProfileScreen(
        name: _name,
        goal: _goal,
        schedule: _schedule,
        bmi: _bmi,
        onGoalsUpdated: _updateGoals,
        onBmiUpdated: _updateBmi,
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
          if (index == 3) {
            _loadWorkoutSession();
          } else if (index == 0) {
            setState(() {
              _homeRefreshSeed++;
            });
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
