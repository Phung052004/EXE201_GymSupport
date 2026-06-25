import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:gym_support/core/constants/app_colors.dart';
import 'package:gym_support/core/constants/app_theme.dart';
import 'package:gym_support/core/services/backend_api.dart';
import 'package:gym_support/models/workout_models.dart';
import 'workout_plans_screen.dart';
import 'workout_session_screen.dart';

class TodayWorkoutScreen extends StatefulWidget {
  const TodayWorkoutScreen({super.key});

  @override
  State<TodayWorkoutScreen> createState() => _TodayWorkoutScreenState();
}

class _TodayWorkoutScreenState extends State<TodayWorkoutScreen> {
  WorkoutPlan? _activePlan;
  WorkoutDay? _selectedDay;
  Map<String, dynamic>? _activeSessionLog;
  bool _isLoading = true;
  String? _error;
  String _todayWeekday = '';
  final Map<String, String> _exerciseImages = {};
  Timer? _previewTimer;
  int _previewTick = 0;

  @override
  void initState() {
    super.initState();
    _todayWeekday = _weekdayName(DateTime.now());
    _previewTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) setState(() => _previewTick++);
    });
    _loadActivePlan();
  }

  @override
  void dispose() {
    _previewTimer?.cancel();
    super.dispose();
  }

  String _weekdayName(DateTime date) {
    const names = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return names[date.weekday];
  }

  Future<void> _loadActivePlan() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final activeSession = await BackendApi.getActiveWorkoutSessionLog();
      if (!mounted) return;
      if (activeSession != null) {
        setState(() {
          _activeSessionLog = activeSession;
          _activePlan = null;
          _selectedDay = null;
          _isLoading = false;
        });
        return;
      }

      final data = await BackendApi.getActiveWorkoutPlan();
      if (!mounted) return;

      if (data != null) {
        final plan = WorkoutPlan.fromJson(data);
        final catalog = await BackendApi.getExercises();
        if (!mounted) return;
        _exerciseImages
          ..clear()
          ..addEntries(catalog.map((e) => MapEntry(e.id, e.imageUrl)));

        WorkoutDay? foundDay;
        for (var day in plan.workoutDays) {
          if (day.weekday.trim().toLowerCase() == _todayWeekday.toLowerCase() ||
              day.dayName.trim().toLowerCase().contains(_todayWeekday.toLowerCase())) {
            foundDay = day;
            break;
          }
        }

        setState(() {
          _activeSessionLog = null;
          _activePlan = plan;
          _selectedDay = foundDay ?? (plan.workoutDays.isNotEmpty ? plan.workoutDays.first : null);
          _isLoading = false;
        });
      } else {
        setState(() { _activeSessionLog = null; _activePlan = null; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Lỗi kết nối: $e'; _isLoading = false; });
    }
  }

  Future<void> _startWorkout() async {
    if (_activePlan == null || _selectedDay == null) return;
    try {
      final session = await BackendApi.startWorkout(
        planId: _activePlan!.id,
        sessionId: _selectedDay!.id,
      );
      final logId = session['id']?.toString();
      if (logId != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WorkoutSessionScreen(
              logId: logId,
              planName: _activePlan!.name,
              dayName: _selectedDay!.dayName,
              focus: _selectedDay!.focus,
              exercises: _selectedDay!.exercises,
            ),
          ),
        ).then((_) => _loadActivePlan());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể bắt đầu: $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _continueActiveWorkout() {
    final log = _activeSessionLog;
    if (log == null) return;
    final parsed = _parseActiveLog(log);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutSessionScreen(
          logId: log['id']?.toString() ?? '',
          planName: log['name']?.toString() ?? 'Unfinished Workout',
          dayName: 'Continue',
          focus: log['focus']?.toString() ?? '',
          exercises: parsed.exercises,
          initialCompletedSets: parsed.completedSets,
          initialReps: parsed.reps,
          initialWeights: parsed.weights,
        ),
      ),
    ).then((_) => _loadActivePlan());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAppBar(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Lịch tập',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ),
          if (_activePlan != null)
            IconButton(
              icon: const Icon(PhosphorIconsBold.arrowClockwise, size: 22),
              color: AppColors.textSecondary,
              onPressed: _loadActivePlan,
            ),
          IconButton(
            icon: const Icon(PhosphorIconsBold.arrowsLeftRight, size: 22),
            color: AppColors.textSecondary,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WorkoutPlansScreen()),
            ).then((_) => _loadActivePlan()),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return _buildSkeleton();
    if (_error != null) {
      return AppErrorState(message: _error!, onRetry: _loadActivePlan);
    }
    if (_activeSessionLog != null) return _buildActiveSession();
    if (_activePlan == null) {
      return AppEmptyState(
        icon: PhosphorIconsBold.barbell,
        title: 'Chưa có lịch tập',
        message: 'Chọn hoặc tạo một lịch tập để bắt đầu theo dõi quá trình luyện tập.',
        buttonLabel: 'Chọn lịch tập',
        onButton: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const WorkoutPlansScreen()),
        ).then((_) => _loadActivePlan()),
      );
    }
    return _buildPlanView();
  }

  Widget _buildSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          SkeletonBox(width: double.infinity, height: 140, radius: AppTheme.radiusXl),
          const SizedBox(height: 12),
          SkeletonBox(width: double.infinity, height: 96, radius: AppTheme.radiusLg),
          const SizedBox(height: 10),
          SkeletonBox(width: double.infinity, height: 96, radius: AppTheme.radiusLg),
          const SizedBox(height: 10),
          SkeletonBox(width: double.infinity, height: 96, radius: AppTheme.radiusLg),
        ],
      ),
    );
  }

  // ── Active session (resume) ───────────────────────────────────────────────

  Widget _buildActiveSession() {
    final log = _activeSessionLog!;
    final parsed = _parseActiveLog(log);
    final completedSets = parsed.completedSets.values
        .fold<int>(0, (sum, list) => sum + list.where((d) => d).length);
    final totalSets = parsed.completedSets.values
        .fold<int>(0, (sum, list) => sum + list.length);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        // Unfinished session hero
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF003D4D), Color(0xFF001820)],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.10),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(PhosphorIconsBold.play, color: AppColors.textDark, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '● ĐANG TIẾN HÀNH',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        'Buổi tập chưa hoàn thành',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _StatPill(label: 'Bài tập', value: '${parsed.exercises.length}'),
                  const SizedBox(width: 10),
                  _StatPill(label: 'Đã xong', value: '$completedSets/$totalSets sets'),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppTheme.cyanGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: ElevatedButton(
                    onPressed: parsed.exercises.isEmpty ? null : _continueActiveWorkout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: AppColors.textDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(PhosphorIconsBold.play, size: 22),
                        SizedBox(width: 8),
                        Text('Tiếp tục Workout', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'CÁC BÀI TẬP',
          style: TextStyle(
            color: AppColors.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        ...parsed.exercises.map((ex) {
          final done = parsed.completedSets[ex.exerciseId]?.where((d) => d).length ?? 0;
          final total = parsed.completedSets[ex.exerciseId]?.length ?? ex.sets;
          final isDone = done >= total;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDone
                  ? AppColors.success.withValues(alpha: 0.05)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: isDone
                    ? AppColors.success.withValues(alpha: 0.25)
                    : AppColors.outline,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isDone ? PhosphorIconsBold.checkCircle : PhosphorIconsRegular.circle,
                  color: isDone ? AppColors.success : AppColors.textSecondary,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    ex.exerciseName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '$done/$total sets',
                  style: TextStyle(
                    color: isDone ? AppColors.success : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── Plan view ─────────────────────────────────────────────────────────────

  Widget _buildPlanView() {
    final sessions = _activePlan!.workoutDays;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        // Plan header card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: AppTheme.heroGradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'KẾ HOẠCH HIỆN TẠI',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _activePlan!.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${sessions.length} buổi/tuần',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _activePlan!.goal.isEmpty ? 'Custom' : _activePlan!.goal,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'BUỔI TẬP',
          style: TextStyle(
            color: AppColors.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        ...sessions.asMap().entries.map((entry) {
          final i = entry.key;
          final day = entry.value;
          final isToday = day.weekday.trim().toLowerCase() == _todayWeekday.toLowerCase();
          final previewExercise = day.exercises.isEmpty
              ? null
              : day.exercises[_previewTick % day.exercises.length];
          final previewImage = previewExercise == null
              ? ''
              : (_exerciseImages[previewExercise.exerciseId] ?? '');

          return Container(
            margin: EdgeInsets.only(bottom: i == sessions.length - 1 ? 0 : 10),
            decoration: BoxDecoration(
              color: isToday
                  ? AppColors.primary.withValues(alpha: 0.06)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(
                color: isToday
                    ? AppColors.primary.withValues(alpha: 0.35)
                    : AppColors.outline,
                width: isToday ? 1.5 : 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                onTap: () => setState(() => _selectedDay = day),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      // Preview image
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: AppColors.surface2,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          child: previewImage.isNotEmpty
                              ? Image.network(
                                  previewImage,
                                  key: ValueKey(previewExercise?.exerciseId ?? i),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => _fallbackImage(),
                                )
                              : _fallbackImage(),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (isToday)
                                  Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: const Text(
                                      'HÔM NAY',
                                      style: TextStyle(
                                        color: AppColors.textDark,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                Flexible(
                                  child: Text(
                                    day.focus.trim().isEmpty ? day.dayName : day.focus,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              [
                                if (day.weekday.isNotEmpty) day.weekday,
                                '${day.exercises.length} bài tập',
                              ].join('  ·  '),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (previewExercise != null) ...[
                              const SizedBox(height: 4),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 400),
                                child: Text(
                                  previewExercise.exerciseName,
                                  key: ValueKey(previewExercise.exerciseId),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                      const SizedBox(width: 10),
                      // Play button
                      GestureDetector(
                        onTap: () {
                          setState(() => _selectedDay = day);
                          _startWorkout();
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isToday ? AppColors.primary : AppColors.surface2,
                            shape: BoxShape.circle,
                            border: isToday
                                ? null
                                : Border.all(color: AppColors.outlineStrong),
                          ),
                          child: Icon(
                            isToday ? PhosphorIconsBold.play : PhosphorIconsBold.arrowRight,
                            color: isToday ? AppColors.textDark : AppColors.textSecondary,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _fallbackImage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2E38), AppColors.surface2],
        ),
      ),
      child: const Center(
        child: Icon(PhosphorIconsBold.barbell, color: AppColors.outlineStrong, size: 26),
      ),
    );
  }

  _ActiveLogData _parseActiveLog(Map<String, dynamic> log) {
    final exercises = <WorkoutExercise>[];
    final completedSets = <String, List<bool>>{};
    final reps = <String, List<int>>{};
    final weights = <String, List<double>>{};

    final rawExercises = log['exercises'] as List? ?? const [];
    for (final raw in rawExercises) {
      if (raw is! Map) continue;
      final item = Map<String, dynamic>.from(raw);
      final exerciseId = item['exerciseId']?.toString() ?? '';
      if (exerciseId.isEmpty) continue;

      final plannedSets = int.tryParse(
            (item['plannedSets'] ?? item['PlannedSets'] ?? 0).toString(),
          ) ??
          0;
      final plannedReps = (item['plannedReps'] ?? item['PlannedReps'] ?? '10').toString();
      final rawSets = item['sets'] as List? ?? const [];

      final completedByNum = <int, bool>{};
      final repsByNum = <int, int>{};
      final weightByNum = <int, double>{};

      for (final rawSet in rawSets) {
        if (rawSet is! Map) continue;
        final s = Map<String, dynamic>.from(rawSet);
        final setNum = int.tryParse(
              (s['setNumber'] ?? s['SetNumber'] ?? 0).toString(),
            ) ??
            0;
        if (setNum <= 0) continue;
        final status = (s['status'] ?? s['Status'] ?? '').toString().toUpperCase();
        completedByNum[setNum] = status == 'COMPLETED';
        repsByNum[setNum] = int.tryParse((s['reps'] ?? s['Reps'] ?? '10').toString()) ?? 10;
        weightByNum[setNum] = double.tryParse((s['weight'] ?? s['Weight'] ?? '0').toString()) ?? 0;
      }

      final maxLogged = completedByNum.keys.fold(0, (m, n) => n > m ? n : m);
      final setCount = plannedSets > 0
          ? (maxLogged > plannedSets ? maxLogged : plannedSets)
          : (maxLogged > 0 ? maxLogged : 3);

      final defaultReps = repsByNum[1]?.toString() ??
          (plannedReps.isNotEmpty ? plannedReps : '10');

      exercises.add(WorkoutExercise(
        exerciseId: exerciseId,
        exerciseName: item['exerciseName']?.toString() ?? 'Exercise',
        sets: setCount,
        reps: defaultReps,
        restTime: 60,
        note: '',
      ));

      completedSets[exerciseId] =
          List.generate(setCount, (i) => completedByNum[i + 1] ?? false);
      reps[exerciseId] =
          List.generate(setCount, (i) => repsByNum[i + 1] ?? int.tryParse(defaultReps) ?? 10);
      weights[exerciseId] =
          List.generate(setCount, (i) => weightByNum[i + 1] ?? 0.0);
    }

    return _ActiveLogData(exercises: exercises, completedSets: completedSets, reps: reps, weights: weights);
  }
}

// ── Stat pill ─────────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  const _StatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveLogData {
  final List<WorkoutExercise> exercises;
  final Map<String, List<bool>> completedSets;
  final Map<String, List<int>> reps;
  final Map<String, List<double>> weights;

  const _ActiveLogData({
    required this.exercises,
    required this.completedSets,
    required this.reps,
    required this.weights,
  });
}
