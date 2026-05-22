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

class HomeScreen extends StatefulWidget {
  final String name;
  final String goal;
  final String schedule;
  final String bmi;

  const HomeScreen({
    super.key,
    required this.name,
    required this.goal,
    required this.schedule,
    required this.bmi,
  });
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _workout;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadWorkout();
  }

  Future<void> _loadWorkout() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString(SessionStore.emailKey);
      if (email != null && email.isNotEmpty) {
        final w = await BackendApi.getWorkoutPlanByEmail(email);
        setState(() => _workout = w);
      }
    } catch (_) {
      // ignore
    } finally {
      setState(() => _loading = false);
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

            const Row(
              children: [
                Expanded(
                  child: HomeStatCard(
                    icon: Icons.local_fire_department,
                    iconColor: Color(0xFFFF7A30),
                    value: '3',
                    label: 'DAY STREAK',
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: HomeStatCard(
                    icon: Icons.emoji_events,
                    iconColor: AppColors.primary,
                    value: '0',
                    label: 'WORKOUTS',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 26),

            const SectionTitle(icon: Icons.bolt, title: "Today's Plan"),

            const SizedBox(height: 12),

            TodayPlanCard(
              onBuildRoutine: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Màn tạo lịch tập sẽ làm ở bước sau'),
                  ),
                );
              },
              workout: _workout,
            ),

            const SizedBox(height: 28),

            const SectionTitle(
              icon: Icons.fitness_center,
              title: 'Muscle Progress',
            ),

            const SizedBox(height: 12),

            const MuscleProgressGrid(),

            const SizedBox(height: 28),

            const SectionTitle(icon: Icons.restaurant, title: 'Nutrition Plan'),

            const SizedBox(height: 12),

            NutritionPlanCard(
              calories: _workout != null ? '${_workout!['nutrition']?['calories'] ?? '—'}' : '2,200',
              protein: _workout != null ? '${_workout!['nutrition']?['protein'] ?? '—'}' : '140g',
              water: '2.5L',
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
