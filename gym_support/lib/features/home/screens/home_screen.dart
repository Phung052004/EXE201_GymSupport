import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import 'package:gym_support/core/services/backend_api.dart';
import 'package:gym_support/core/services/session_store.dart';
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
                    id:
                        data['muscleId']?.toString() ??
                        data['id']?.toString() ??
                        '',
                    name: data['name']?.toString() ?? 'Unknown',
                    category: data['category']?.toString() ?? '',
                    level:
                        int.tryParse(
                          data['level']
                                  ?.toString()
                                  .replaceAll('Lv', '')
                                  .trim() ??
                              '',
                        ) ??
                        1,
                    totalExp:
                        int.tryParse(data['totalExp']?.toString() ?? '') ?? 0,
                    currentLevelExp:
                        int.tryParse(
                          data['currentLevelExp']?.toString() ?? '',
                        ) ??
                        _xpCurrent(data['xp']),
                    expToNextLevel:
                        int.tryParse(
                          data['expToNextLevel']?.toString() ?? '',
                        ) ??
                        100,
                    progress: (data['progress'] is num)
                        ? (data['progress'] as num)
                              .toDouble()
                              .clamp(0.0, 1.0)
                              .toDouble()
                        : 0,
                    tier: data['tier']?.toString() ?? 'Iron',
                    isLagging: data['isLagging'] == true,
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

  int _xpCurrent(dynamic value) {
    final raw = value?.toString() ?? '';
    return int.tryParse(raw.split('/').first.trim()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.name.isEmpty ? 'User' : widget.name;
    final displayGoal = widget.goal.isEmpty ? 'Fitness Goal' : widget.goal;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadWorkout,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HomeHeader(name: displayName, goal: displayGoal),

                const SizedBox(height: 32),

                Row(
                  children: [
                    Expanded(
                      child: HomeStatCard(
                        icon: Icons.local_fire_department_rounded,
                        iconColor: AppColors.accent,
                        value: '${_home?['streak'] ?? 0}',
                        label: 'DAY STREAK',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const WorkoutHistoryScreen(),
                            ),
                          );
                        },
                        child: HomeStatCard(
                          icon: Icons.emoji_events_rounded,
                          iconColor: AppColors.primary,
                          value: '${_home?['workoutCount'] ?? 0}',
                          label: 'WORKOUTS',
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                const SectionTitle(
                  icon: Icons.bolt_rounded,
                  title: "Today's Plan",
                ),

                const SizedBox(height: 16),

                TodayPlanCard(
                  isLoading: _loading,
                  onBuildRoutine: widget.onBuildRoutine,
                  workout: _workout,
                ),

                const SizedBox(height: 32),

                const SectionTitle(
                  icon: Icons.fitness_center_rounded,
                  title: 'Muscle Progress',
                ),

                const SizedBox(height: 16),

                MuscleProgressGrid(items: _muscleProgress, isLoading: _loading),

                const SizedBox(height: 32),

                const SectionTitle(
                  icon: Icons.restaurant_rounded,
                  title: 'Nutrition Plan',
                ),

                const SizedBox(height: 16),

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

                const SizedBox(height: 24),
              ],
            ),
          ),
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
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
