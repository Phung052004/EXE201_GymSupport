import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/services/backend_api.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/session_store.dart';
import '../../workout/screens/workout_history_screen.dart';
import '../widgets/muscle_progress_card.dart';
import '../widgets/muscle_progress_teaser.dart';
import '../widgets/nutrition_plan_card.dart';
import '../widgets/popular_exercises_section.dart';
import '../widgets/today_plan_card.dart';
import '../widgets/weekly_activity_card.dart';

class HomeScreen extends StatefulWidget {
  final String name;
  final String goal;
  final String schedule;
  final String bmi;
  final int refreshSeed;
  final VoidCallback onBuildRoutine;
  final VoidCallback onOpenWorkout;

  const HomeScreen({
    super.key,
    required this.name,
    required this.goal,
    required this.schedule,
    required this.bmi,
    required this.refreshSeed,
    required this.onBuildRoutine,
    required this.onOpenWorkout,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _workout;
  Map<String, dynamic>? _home;
  List<MuscleProgressData> _muscleProgress = const [];
  List<Map<String, dynamic>> _popularExercises = const [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSeed != widget.refreshSeed) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString(SessionStore.emailKey);
      if (email == null || email.isEmpty) return;

      final home = await BackendApi.getHomeSummary(email);
      final todayPlan = home['todayPlan'] as Map<String, dynamic>?;
      final nutrition = home['nutrition'] as Map<String, dynamic>?;
      final progress = home['muscleProgress'];
      final popular = home['popularExercises'];

      if (!mounted) return;
      setState(() {
        _home = home;
        _workout = todayPlan == null
            ? null
            : {'workoutPlan': [todayPlan], 'nutrition': nutrition};
        _muscleProgress = _parseMuscleProgress(progress);
        _popularExercises = popular is List
            ? popular
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList()
            : const [];
      });

      // Schedule local workout reminders from the active plan's sessions
      _scheduleReminders(home['plans']);
    } catch (_) {
      // Fail silently — UI shows empty states
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scheduleReminders(dynamic plans) {
    if (plans is! List) return;
    // Collect scheduled days from the first active plan
    final activePlan = plans
        .whereType<Map>()
        .firstWhere((p) => p['isActive'] == true, orElse: () => plans.first as Map);
    final sessions = activePlan['sessions'] as List? ?? activePlan['Sessions'] as List? ?? [];
    final days = sessions
        .whereType<Map>()
        .map((s) => s['dayOfWeek']?.toString() ?? s['DayOfWeek']?.toString() ?? '')
        .where((d) => d.isNotEmpty)
        .toList();
    if (days.isEmpty) return;
    final planName = activePlan['name']?.toString() ?? activePlan['Name']?.toString() ?? '';
    NotificationService.requestPermission().then((_) {
      NotificationService.scheduleWorkoutReminders(days: days, planName: planName);
    });
  }

  List<MuscleProgressData> _parseMuscleProgress(dynamic progress) {
    if (progress is! List) return const [];
    return progress.whereType<Map>().map((item) {
      final data = Map<String, dynamic>.from(item);
      return MuscleProgressData(
        id: data['muscleId']?.toString() ?? data['id']?.toString() ?? '',
        name: data['name']?.toString() ?? 'Unknown',
        category: data['category']?.toString() ?? '',
        level: int.tryParse(
              data['level']?.toString().replaceAll('Lv', '').trim() ?? '',
            ) ??
            1,
        totalExp: int.tryParse(data['totalExp']?.toString() ?? '') ?? 0,
        currentLevelExp:
            int.tryParse(data['currentLevelExp']?.toString() ?? '') ??
            _xpCurrent(data['xp']),
        expToNextLevel:
            int.tryParse(data['expToNextLevel']?.toString() ?? '') ?? 100,
        progress: (data['progress'] is num)
            ? (data['progress'] as num).toDouble().clamp(0.0, 1.0)
            : 0,
        tier: data['tier']?.toString() ?? 'Iron',
        isLagging: data['isLagging'] == true,
      );
    }).toList();
  }

  int _xpCurrent(dynamic value) {
    final raw = value?.toString() ?? '';
    return int.tryParse(raw.split('/').first.trim()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final firstName = widget.name.isEmpty
        ? 'Bạn'
        : widget.name.split(' ').last;
    final streak = _home?['streak'] ?? 0;
    final workoutCount = _home?['workoutCount'] ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Header ──────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _HomeHeader(
                  firstName: firstName,
                  goal: widget.goal,
                  streak: streak,
                  workoutCount: workoutCount,
                  isLoading: _loading,
                  onHistory: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WorkoutHistoryScreen(),
                    ),
                  ),
                ),
              ),

              // ── Today's Workout ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionHeader(
                        title: "Hôm nay tập gì?",
                        actionLabel: 'Lịch tập',
                        onAction: widget.onBuildRoutine,
                      ),
                      const SizedBox(height: 14),
                      TodayPlanCard(
                        isLoading: _loading,
                        onBuildRoutine: widget.onBuildRoutine,
                        onOpenWorkout: widget.onOpenWorkout,
                        workout: _workout,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Popular Exercises ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionHeader(title: 'Bài tập phổ biến'),
                      const SizedBox(height: 14),
                      PopularExercisesSection(
                        items: _popularExercises,
                        isLoading: _loading,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Weekly Activity ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                  child: WeeklyActivityCard(isLoading: _loading, weeklyCount: workoutCount),
                ),
              ),

              // ── Muscle Progress ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionHeader(title: 'Tiến độ cơ bắp'),
                      const SizedBox(height: 14),
                      MuscleProgressTeaser(
                        items: _muscleProgress,
                        isLoading: _loading,
                        onViewAll: () => Navigator.pushNamed(
                          context,
                          '/muscle-detail',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Nutrition ────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionHeader(title: 'Dinh dưỡng hôm nay'),
                      const SizedBox(height: 14),
                      NutritionPlanCard(
                        calories: _workout?['nutrition']?['calories']?.toString() ?? '—',
                        protein: _workout?['nutrition']?['protein']?.toString() ?? '—',
                        water: _workout?['nutrition']?['water']?.toString() ?? '—',
                        bmi: widget.bmi,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header component ─────────────────────────────────────────────────────────

class _HomeHeader extends StatelessWidget {
  final String firstName;
  final String goal;
  final int streak;
  final int workoutCount;
  final bool isLoading;
  final VoidCallback onHistory;

  const _HomeHeader({
    required this.firstName,
    required this.goal,
    required this.streak,
    required this.workoutCount,
    required this.isLoading,
    required this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          image: DecorationImage(
            image: CachedNetworkImageProvider(AppImages.gymHero),
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xF0060E10), // near-opaque left
                Color(0xC0060E10), // semi-transparent right
                Color(0x88003D4D), // teal-tinted far right
              ],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Xin chào,',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$firstName 👋',
                          style: AppTheme.displaySmall.copyWith(
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (goal.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              goal,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: onHistory,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: const Icon(
                        PhosphorIconsBold.clockCounterClockwise,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Stats row — 3 mini cards
              if (isLoading)
                Row(
                  children: [
                    Expanded(child: SkeletonBox(width: double.infinity, height: 64, radius: AppTheme.radiusMd)),
                    const SizedBox(width: 10),
                    Expanded(child: SkeletonBox(width: double.infinity, height: 64, radius: AppTheme.radiusMd)),
                    const SizedBox(width: 10),
                    Expanded(child: SkeletonBox(width: double.infinity, height: 64, radius: AppTheme.radiusMd)),
                  ],
                )
              else
                Row(
                  children: [
                    _MiniStatCard(
                      icon: PhosphorIconsBold.fire,
                      iconColor: const Color(0xFFFF6B35),
                      value: '$streak',
                      label: 'Streak',
                    ),
                    const SizedBox(width: 10),
                    _MiniStatCard(
                      icon: PhosphorIconsBold.barbell,
                      iconColor: AppColors.primary,
                      value: '$workoutCount',
                      label: 'Buổi tập',
                    ),
                    const SizedBox(width: 10),
                    _MiniStatCard(
                      icon: PhosphorIconsBold.trendUp,
                      iconColor: AppColors.success,
                      value: _muscleCount(workoutCount),
                      label: 'Tuần này',
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _muscleCount(int total) {
    // Weekly count approximation — shown as buổi/tuần
    return total > 0 ? '${total % 7 == 0 ? 7 : total % 7}' : '0';
  }
}

class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _MiniStatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}
