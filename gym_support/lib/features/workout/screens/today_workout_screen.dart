import 'package:flutter/material.dart';
import 'package:gym_support/core/constants/app_colors.dart';
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

  @override
  void initState() {
    super.initState();
    _todayWeekday = _getWeekdayName(DateTime.now());
    _loadActivePlan();
  }

  String _getWeekdayName(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return '';
    }
  }

  Future<void> _loadActivePlan() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
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
        WorkoutDay? foundDay;

        final currentWeekday = _todayWeekday.trim().toLowerCase();

        // Try to find today's day in the plan
        for (var day in plan.workoutDays) {
          final dayWeekday = day.weekday.trim().toLowerCase();
          final dayName = day.dayName.trim().toLowerCase();

          if (dayWeekday == currentWeekday ||
              dayName.contains(currentWeekday)) {
            foundDay = day;
            break;
          }
        }

        setState(() {
          _activeSessionLog = null;
          _activePlan = plan;
          // Auto-select today if found, otherwise keep first day or null
          _selectedDay =
              foundDay ??
              (plan.workoutDays.isNotEmpty ? plan.workoutDays.first : null);
          _isLoading = false;
        });
      } else {
        setState(() {
          _activeSessionLog = null;
          _activePlan = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Lỗi kết nối: $e';
          _isLoading = false;
        });
      }
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể bắt đầu: $e')));
      }
    }
  }

  void _continueActiveWorkout() {
    final log = _activeSessionLog;
    if (log == null) return;

    final parsed = _activeLogToSessionData(log);
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
      appBar: AppBar(
        title: const Text(
          'Today Workout',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_activePlan != null)
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: _loadActivePlan,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadActivePlan,
                child: const Text('THỬ LẠI'),
              ),
            ],
          ),
        ),
      );
    }

    if (_activeSessionLog != null) {
      return _buildActiveSessionState();
    }

    if (_activePlan == null) {
      return _buildEmptyState();
    }

    return _buildActiveState();
  }

  Widget _buildActiveSessionState() {
    final parsed = _activeLogToSessionData(_activeSessionLog!);
    final completedSets = parsed.completedSets.values.fold<int>(
      0,
      (sum, list) => sum + list.where((done) => done).length,
    );
    final totalSets = parsed.completedSets.values.fold<int>(
      0,
      (sum, list) => sum + list.length,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.25),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'UNFINISHED WORKOUT',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  _activeSessionLog!['name']?.toString() ?? 'Continue workout',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You have a workout in progress. Finish it before starting another plan.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.58),
                    fontSize: 13,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _miniProgressStat(
                      'Exercises',
                      '${parsed.exercises.length}',
                    ),
                    const SizedBox(width: 10),
                    _miniProgressStat('Sets', '$completedSets/$totalSets'),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: parsed.exercises.isEmpty
                        ? null
                        : _continueActiveWorkout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'CONTINUE WORKOUT',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'REMAINING EXERCISES',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          ...parsed.exercises.map((exercise) {
            final done =
                parsed.completedSets[exercise.exerciseId]
                    ?.where((value) => value)
                    .length ??
                0;
            final total =
                parsed.completedSets[exercise.exerciseId]?.length ??
                exercise.sets;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  Icon(
                    done >= total
                        ? Icons.check_circle
                        : Icons.timelapse_rounded,
                    color: done >= total
                        ? AppColors.primary
                        : AppColors.secondary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      exercise.exerciseName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '$done/$total sets',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _miniProgressStat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.42),
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _ActiveLogSessionData _activeLogToSessionData(Map<String, dynamic> log) {
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

      final rawSets = item['sets'] as List? ?? const [];
      final completed = <bool>[];
      final setReps = <int>[];
      final setWeights = <double>[];

      for (final rawSet in rawSets) {
        if (rawSet is! Map) continue;
        final set = Map<String, dynamic>.from(rawSet);
        final status = (set['status'] ?? set['Status'] ?? '')
            .toString()
            .toUpperCase();
        completed.add(status == 'COMPLETED');
        setReps.add(
          int.tryParse((set['reps'] ?? set['Reps'] ?? '10').toString()) ?? 10,
        );
        setWeights.add(
          double.tryParse((set['weight'] ?? set['Weight'] ?? '0').toString()) ??
              0,
        );
      }

      final setCount = completed.isEmpty ? 3 : completed.length;
      exercises.add(
        WorkoutExercise(
          exerciseId: exerciseId,
          exerciseName: item['exerciseName']?.toString() ?? 'Exercise',
          sets: setCount,
          reps: setReps.isEmpty ? '10' : '${setReps.first}',
          restTime: 60,
          note: '',
        ),
      );
      completedSets[exerciseId] = completed.isEmpty
          ? List.generate(setCount, (_) => false)
          : completed;
      reps[exerciseId] = setReps.isEmpty
          ? List.generate(setCount, (_) => 10)
          : setReps;
      weights[exerciseId] = setWeights.isEmpty
          ? List.generate(setCount, (_) => 0)
          : setWeights;
    }

    return _ActiveLogSessionData(
      exercises: exercises,
      completedSets: completedSets,
      reps: reps,
      weights: weights,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.fitness_center, size: 80, color: Colors.white10),
            const SizedBox(height: 24),
            const Text(
              'Bạn chưa chọn lịch tập nào',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Hãy chọn hoặc tạo một lịch tập để bắt đầu theo dõi quá trình luyện tập.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WorkoutPlansScreen(),
                    ),
                  ).then((_) => _loadActivePlan());
                },
                child: const Text('CHOOSE WORKOUT PLAN'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plan Selector Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: AppColors.primary, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ACTIVE PLAN',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        _activePlan!.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WorkoutPlansScreen(),
                      ),
                    ).then((_) => _loadActivePlan());
                  },
                  icon: const Icon(Icons.swap_horiz, color: AppColors.primary),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),
          const Text(
            'SELECT WORKOUT DAY',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<WorkoutDay>(
                value: _selectedDay,
                isExpanded: true,
                dropdownColor: AppColors.surface,
                items: _activePlan!.workoutDays.map((day) {
                  final isToday =
                      day.weekday.trim().toLowerCase() ==
                      _todayWeekday.trim().toLowerCase();
                  return DropdownMenuItem<WorkoutDay>(
                    value: day,
                    child: Text(
                      '${day.dayName} (${day.weekday})${isToday ? " - TODAY" : ""}',
                      style: TextStyle(
                        color: isToday ? AppColors.primary : Colors.white,
                        fontWeight: isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (day) {
                  setState(() {
                    _selectedDay = day;
                  });
                },
              ),
            ),
          ),

          const SizedBox(height: 32),
          Text(
            _selectedDay?.dayName.toUpperCase() ?? 'EXERCISES',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),

          if (_selectedDay != null)
            ..._selectedDay!.exercises.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final ex = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        '$index',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ex.exerciseName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${ex.sets} sets x ${ex.reps}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _selectedDay == null ? null : _startWorkout,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                shadowColor: AppColors.primary.withValues(alpha: 0.4),
              ),
              child: const Text(
                'START WORKOUT',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _ActiveLogSessionData {
  final List<WorkoutExercise> exercises;
  final Map<String, List<bool>> completedSets;
  final Map<String, List<int>> reps;
  final Map<String, List<double>> weights;

  const _ActiveLogSessionData({
    required this.exercises,
    required this.completedSets,
    required this.reps,
    required this.weights,
  });
}
