import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import 'package:gym_support/core/services/backend_api.dart';
import 'package:gym_support/core/services/session_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/home_header.dart';
import '../widgets/home_stat_card.dart';
import '../widgets/muscle_progress_card.dart';
import '../widgets/nutrition_plan_card.dart';
import '../widgets/today_plan_card.dart';

import 'package:gym_support/features/workout/screens/workout_history_screen.dart';

class HomeScreen extends StatefulWidget {
  final String name;
  final String goal;
  final String schedule;
  final String bmi;
  final int refreshSeed;
  final VoidCallback onBuildRoutine;

  const HomeScreen({
    super.key,
    required this.name,
    required this.goal,
    required this.schedule,
    required this.bmi,
    required this.refreshSeed,
    required this.onBuildRoutine,
  });
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _workout;
  Map<String, dynamic>? _home;
  List<MuscleProgressData> _muscleProgress = const [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadWorkout();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSeed != widget.refreshSeed) {
      _loadWorkout();
    }
  }

  Future<void> _loadWorkout() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString(SessionStore.emailKey);
      if (email != null && email.isNotEmpty) {
        final home = await BackendApi.getHomeSummary(email);
        final todayPlan = home['todayPlan'] as Map<String, dynamic>?;
        final nutrition = home['nutrition'] as Map<String, dynamic>?;
        final progress = home['muscleProgress'];
        setState(() {
          _home = home;
          _workout = todayPlan == null
              ? null
              : {
                  'workoutPlan': [todayPlan],
                  'nutrition': nutrition,
                };
          _muscleProgress = progress is List
              ? progress.whereType<Map>().map((item) {
                  final data = Map<String, dynamic>.from(item);
                  return MuscleProgressData(
                    name: data['name']?.toString() ?? 'Unknown',
                    level: data['level']?.toString() ?? 'Lv 1',
                    progress: (data['progress'] is num)
                        ? (data['progress'] as num)
                              .toDouble()
                              .clamp(0.0, 1.0)
                              .toDouble()
                        : 0,
                    xp: data['xp']?.toString() ?? '0/100 XP',
                  );
                }).toList()
              : const [];
        });
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không tải được Home: $error')));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomeHeader(name: widget.name, goal: widget.goal),

            const SizedBox(height: 22),

            Row(
              children: [
                Expanded(
                  child: HomeStatCard(
                    icon: Icons.local_fire_department,
                    iconColor: Color(0xFFFF7A30),
                    value: '${_home?['streak'] ?? 0}',
                    label: 'DAY STREAK',
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const WorkoutHistoryScreen()),
                      );
                    },
                    child: HomeStatCard(
                      icon: Icons.emoji_events,
                      iconColor: AppColors.primary,
                      value: '${_home?['workoutCount'] ?? 0}',
                      label: 'WORKOUTS',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 26),

            const SectionTitle(icon: Icons.bolt, title: "Today's Plan"),

            const SizedBox(height: 12),

            TodayPlanCard(
              isLoading: _loading,
              onBuildRoutine: widget.onBuildRoutine,
              workout: _workout,
            ),

            const SizedBox(height: 28),

            const SectionTitle(
              icon: Icons.fitness_center,
              title: 'Muscle Progress',
            ),

            const SizedBox(height: 12),

            MuscleProgressGrid(items: _muscleProgress, isLoading: _loading),

            const SizedBox(height: 28),

            const SectionTitle(icon: Icons.restaurant, title: 'Nutrition Plan'),

            const SizedBox(height: 12),

            NutritionPlanCard(
              calories: _workout != null
                  ? '${_workout!['nutrition']?['calories'] ?? '—'}'
                  : '—',
              protein: _workout != null
                  ? '${_workout!['nutrition']?['protein'] ?? '—'}'
                  : '—',
              water: _workout != null
                  ? '${_workout!['nutrition']?['water'] ?? '—'}'
                  : '—',
              bmi: widget.bmi,
            ),

            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const SectionTitle({super.key, required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
