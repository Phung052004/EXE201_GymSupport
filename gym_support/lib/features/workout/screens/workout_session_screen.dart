import 'dart:async';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:gym_support/core/constants/app_colors.dart';
import 'package:gym_support/core/constants/app_theme.dart';
import 'package:gym_support/core/services/backend_api.dart';
import 'package:gym_support/models/workout_models.dart';
import '../../../core/services/notification_service.dart';
import 'workout_summary_screen.dart';

class WorkoutSessionScreen extends StatefulWidget {
  final String logId;
  final String planName;
  final String dayName;
  final String focus;
  final List<WorkoutExercise> exercises;
  final Map<String, List<bool>> initialCompletedSets;
  final Map<String, List<int>> initialReps;
  final Map<String, List<double>> initialWeights;

  const WorkoutSessionScreen({
    super.key,
    required this.logId,
    required this.planName,
    required this.dayName,
    required this.focus,
    required this.exercises,
    this.initialCompletedSets = const {},
    this.initialReps = const {},
    this.initialWeights = const {},
  });

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  late Stopwatch _stopwatch;
  late Timer _timer;
  String _timeDisplay = '00:00:00';

  final Map<String, List<bool>> _completedSets = {};
  final Map<String, List<TextEditingController>> _repsControllers = {};
  final Map<String, List<TextEditingController>> _weightControllers = {};
  final Set<String> _savingSets = {};
  // null = loading, {} = not found
  final Map<String, Map<String, dynamic>?> _exerciseStats = {};

  bool _isSaving = false;
  int _selectedExerciseIndex = 0;
  // exerciseId → { exerciseName, value } for PRs set this session
  final Map<String, Map<String, String>> _newPRs = {};

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _timer = Timer.periodic(const Duration(seconds: 1), _onTick);

    for (final ex in widget.exercises) {
      final completed = widget.initialCompletedSets[ex.exerciseId] ?? [];
      final reps      = widget.initialReps[ex.exerciseId] ?? [];
      final weights   = widget.initialWeights[ex.exerciseId] ?? [];
      final count     = [ex.sets, completed.length, reps.length, weights.length]
          .reduce((a, b) => a > b ? a : b);

      _completedSets[ex.exerciseId] = List.generate(
        count, (i) => i < completed.length ? completed[i] : false);
      _repsControllers[ex.exerciseId] = List.generate(
        count, (i) => TextEditingController(
          text: i < reps.length ? '${reps[i]}' : _extractReps(ex.reps)));
      _weightControllers[ex.exerciseId] = List.generate(
        count, (i) => TextEditingController(
          text: i < weights.length ? '${weights[i]}' : '0'));
    }

    _loadAllExerciseStats();
  }

  void _loadAllExerciseStats() {
    for (final ex in widget.exercises) {
      BackendApi.getExerciseStats(ex.exerciseId).then((stats) {
        if (!mounted) return;
        setState(() => _exerciseStats[ex.exerciseId] = stats ?? {});
      });
    }
  }

  String _extractReps(String repsStr) =>
      RegExp(r'(\d+)').firstMatch(repsStr)?.group(1) ?? '10';

  void _onTick(Timer _) {
    if (_stopwatch.isRunning && mounted) {
      setState(() => _timeDisplay = _fmt(_stopwatch.elapsed));
    }
  }

  String _fmt(Duration d) {
    String p(int n) => n.toString().padLeft(2, '0');
    return '${p(d.inHours)}:${p(d.inMinutes.remainder(60))}:${p(d.inSeconds.remainder(60))}';
  }

  @override
  void dispose() {
    _timer.cancel();
    _stopwatch.stop();
    for (final list in _repsControllers.values) {
      for (final c in list) { c.dispose(); }
    }
    for (final list in _weightControllers.values) {
      for (final c in list) { c.dispose(); }
    }
    super.dispose();
  }

  Future<void> _doneSet(WorkoutExercise ex, int setIdx) async {
    final key = '${ex.exerciseId}:$setIdx';
    if (_savingSets.contains(key)) return;
    final reps   = int.tryParse(_repsControllers[ex.exerciseId]![setIdx].text) ?? 0;
    final weight = double.tryParse(_weightControllers[ex.exerciseId]![setIdx].text) ?? 0;
    if (reps <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nhập số reps hợp lệ trước khi lưu set.')),
      );
      return;
    }
    setState(() => _savingSets.add(key));
    try {
      await BackendApi.saveSetLog(
        logId: widget.logId,
        exerciseId: ex.exerciseId,
        setNumber: setIdx + 1,
        reps: reps,
        weight: weight,
      );
      if (mounted) {
        setState(() => _completedSets[ex.exerciseId]![setIdx] = true);
        _checkPR(ex, weight, reps);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Không thể lưu: $e')));
      }
    } finally {
      if (mounted) setState(() => _savingSets.remove(key));
    }
  }

  void _checkPR(WorkoutExercise ex, double weight, int reps) {
    final pr = _exerciseStats[ex.exerciseId]?['personalRecord'] as Map<String, dynamic>?;
    if (pr == null) return;

    final prevMaxWeight = (pr['maxWeight'] as num?)?.toDouble() ?? 0;
    final prevMaxReps   = (pr['maxReps']   as num?)?.toInt()    ?? 0;

    final isNewPR = weight > prevMaxWeight ||
        (weight >= prevMaxWeight && reps > prevMaxReps);
    if (!isNewPR) return;

    final wStr = weight == weight.truncateToDouble()
        ? '${weight.toInt()}kg'
        : '${weight.toStringAsFixed(1)}kg';
    final label = '$wStr × $reps reps';

    setState(() => _newPRs[ex.exerciseId] = {
      'exerciseName': ex.exerciseName,
      'value': label,
    });

    // In-session banner
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('🏆 New PR! ${ex.exerciseName} — $label'),
      backgroundColor: AppColors.gold,
      duration: const Duration(seconds: 3),
    ));

    // System notification (fires in background)
    NotificationService.showPRNotification(ex.exerciseName, label);
  }

  Future<void> _finishWorkout() async {
    if (_savingSets.isNotEmpty) return;
    final doneCount = _completedSets.values
        .fold<int>(0, (s, list) => s + list.where((d) => d).length);
    if (doneCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hoàn thành ít nhất một set trước nhé.')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final result = await BackendApi.completeWorkout(
        email: '',
        sessionLogId: widget.logId,
      );
      if (!mounted) return;
      _stopwatch.stop();
      _timer.cancel();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => WorkoutSummaryScreen(
            summary: {
              ...result,
              'planName': widget.planName,
              'dayName': widget.dayName,
              'duration': _timeDisplay,
              'exercises': widget.exercises.map((e) => {
                'name': e.exerciseName,
                'sets': _completedSets[e.exerciseId]!.where((d) => d).length,
              }).toList(),
              'newPRs': _newPRs.values.toList(),
            },
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  // ── computed ──────────────────────────────────────────────────────────────
  int get _totalSets => _completedSets.values
      .fold(0, (s, l) => s + l.length);
  int get _doneSets => _completedSets.values
      .fold(0, (s, l) => s + l.where((d) => d).length);

  @override
  Widget build(BuildContext context) {
    final ex = widget.exercises.isEmpty
        ? null
        : widget.exercises[_selectedExerciseIndex];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildProgress(),
            if (widget.exercises.length > 1) _buildExTabs(),
            if (ex != null)
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: KeyedSubtree(
                    key: ValueKey(_selectedExerciseIndex),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                      child: _buildExBlock(ex),
                    ),
                  ),
                ),
              ),
            _buildFinishBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Column(
      children: [
        // Nav row
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(PhosphorIconsBold.caretLeft,
                    color: AppColors.textSecondary, size: 20),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.planName,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis),
                    Text(widget.dayName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Timer card — prominent display
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF003D4D), Color(0xFF001820)],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'THỜI GIAN',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _timeDisplay.substring(3), // MM:SS
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                        fontFeatures: [FontFeature.tabularFigures()],
                        height: 1,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _SessionStatMini(
                      label: 'Bài tập',
                      value: '${_selectedExerciseIndex + 1}/${widget.exercises.length}',
                    ),
                    const SizedBox(width: 16),
                    _SessionStatMini(
                      label: 'Sets xong',
                      value: '$_doneSets/$_totalSets',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgress() {
    final progress = _totalSets == 0 ? 0.0 : _doneSets / _totalSets;
    final pct = (_doneSets / (_totalSets == 0 ? 1 : _totalSets) * 100).round();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$_doneSets / $_totalSets sets hoàn thành',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '$pct%',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.surface2,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExTabs() {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
        scrollDirection: Axis.horizontal,
        itemCount: widget.exercises.length,
        separatorBuilder: (context, i) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final ex = widget.exercises[i];
          final done = _completedSets[ex.exerciseId]?.where((d) => d).length ?? 0;
          final total = _completedSets[ex.exerciseId]?.length ?? 0;
          final allDone = total > 0 && done == total;
          final selected = i == _selectedExerciseIndex;
          return GestureDetector(
            onTap: () => setState(() => _selectedExerciseIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: selected
                      ? AppColors.primary
                      : allDone
                          ? AppColors.success.withValues(alpha: 0.5)
                          : AppColors.outlineStrong,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (allDone)
                    Icon(
                      PhosphorIconsBold.checkCircle,
                      size: 13,
                      color: selected ? AppColors.textDark : AppColors.success,
                    ),
                  if (allDone) const SizedBox(width: 5),
                  Text(
                    ex.exerciseName.length > 12
                        ? '${ex.exerciseName.substring(0, 10)}…'
                        : ex.exerciseName,
                    style: TextStyle(
                      color: selected ? AppColors.textDark : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExBlock(WorkoutExercise ex) {
    final sets        = _completedSets[ex.exerciseId]!;
    final repsCtrl    = _repsControllers[ex.exerciseId]!;
    final weightCtrl  = _weightControllers[ex.exerciseId]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Exercise title card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.cardDecoration(radius: AppTheme.radiusLg),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(PhosphorIconsBold.barbell,
                    color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ex.exerciseName, style: AppTheme.headlineSmall),
                    const SizedBox(height: 2),
                    Text(
                      '${ex.muscleGroup}  ·  ${sets.length} sets × ${ex.reps}',
                      style: AppTheme.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),
        _buildLastPerfBanner(ex),
        const SizedBox(height: 12),

        // Table header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusMd)),
          ),
          child: const Row(
            children: [
              SizedBox(
                width: 36,
                child: Text('SET', style: TextStyle(
                  color: AppColors.textTertiary, fontSize: 10,
                  fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              ),
              Expanded(child: Center(child: Text('KG', style: TextStyle(
                color: AppColors.textTertiary, fontSize: 10,
                fontWeight: FontWeight.w800, letterSpacing: 0.5)))),
              Expanded(child: Center(child: Text('REPS', style: TextStyle(
                color: AppColors.textTertiary, fontSize: 10,
                fontWeight: FontWeight.w800, letterSpacing: 0.5)))),
              SizedBox(width: 52),
            ],
          ),
        ),

        // Set rows
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.outline),
            borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(AppTheme.radiusMd)),
          ),
          child: Column(
            children: sets.asMap().entries.map((entry) {
              final i    = entry.key;
              final done = entry.value;
              final saveKey = '${ex.exerciseId}:$i';
              final saving  = _savingSets.contains(saveKey);

              return Container(
                decoration: BoxDecoration(
                  color: done
                      ? AppColors.success.withValues(alpha: 0.06)
                      : Colors.transparent,
                  border: i > 0
                      ? const Border(top: BorderSide(color: AppColors.outline))
                      : null,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    // Set number
                    SizedBox(
                      width: 36,
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          color: done ? AppColors.success : AppColors.textSecondary,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    // Weight input
                    Expanded(
                      child: _SetInput(
                        controller: weightCtrl[i],
                        enabled: !done,
                        hint: '0',
                        suffix: 'kg',
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Reps input
                    Expanded(
                      child: _SetInput(
                        controller: repsCtrl[i],
                        enabled: !done,
                        hint: '0',
                        suffix: 'reps',
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Done button / check
                    SizedBox(
                      width: 44,
                      height: 36,
                      child: done
                          ? const Icon(PhosphorIconsBold.checkCircle,
                              color: AppColors.success, size: 26)
                          : GestureDetector(
                              onTap: saving ? null : () => _doneSet(ex, i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: saving
                                    ? const Center(
                                        child: SizedBox(
                                          width: 16, height: 16,
                                          child: CircularProgressIndicator(
                                            color: AppColors.textDark,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      )
                                    : const Icon(PhosphorIconsBold.check,
                                        color: AppColors.textDark, size: 20),
                              ),
                            ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),

        // AI Tip
        if (ex.note.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.violet.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppColors.violet.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(PhosphorIconsBold.lightbulb,
                    color: AppColors.violet, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(ex.note, style: AppTheme.bodyMedium),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLastPerfBanner(WorkoutExercise ex) {
    final stats = _exerciseStats[ex.exerciseId];

    // Still loading
    if (stats == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppColors.outline),
        ),
        child: const Row(
          children: [
            SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textTertiary)),
            SizedBox(width: 10),
            Text('Đang tải lịch sử...', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
          ],
        ),
      );
    }

    final lastPerf = stats['lastPerformance'] as Map<String, dynamic>?;
    final pr       = stats['personalRecord'] as Map<String, dynamic>?;

    if (lastPerf == null && pr == null) return const SizedBox.shrink();

    final lastSets = (lastPerf?['sets'] as List?)
        ?.whereType<Map<String, dynamic>>()
        .toList() ?? [];
    final lastDate = lastPerf?['date'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              const Icon(PhosphorIconsBold.clockCounterClockwise, size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                lastDate.isNotEmpty ? 'Lần trước  $lastDate' : 'Lần trước',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              if (pr != null) ...[
                const Spacer(),
                const Icon(PhosphorIconsBold.trophy, size: 12, color: AppColors.gold),
                const SizedBox(width: 4),
                Text(
                  'Kỷ lục: ${(pr['maxWeight'] as num).toStringAsFixed(pr['maxWeight'] % 1 == 0 ? 0 : 1)}kg × ${pr['maxReps']}',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
          if (lastSets.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: lastSets.map((s) {
                final w = (s['weight'] as num?)?.toDouble() ?? 0;
                final r = (s['reps'] as num?)?.toInt() ?? 0;
                final wStr = w == w.truncateToDouble()
                    ? '${w.toInt()}kg'
                    : '${w.toStringAsFixed(1)}kg';
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Set ${s['setNumber']}: $wStr × $r',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFinishBar() {
    final canFinish = !_isSaving && _savingSets.isEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.outline)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: canFinish ? AppTheme.cyanGradient : null,
            color: canFinish ? null : AppColors.surface2,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: ElevatedButton(
            onPressed: canFinish ? _finishWorkout : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              foregroundColor: AppColors.textDark,
              disabledForegroundColor: AppColors.textSecondary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                      color: AppColors.textSecondary, strokeWidth: 2.5,
                    ),
                  )
                : const Text(
                    'Hoàn thành buổi tập',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                  ),
          ),
        ),
      ),
    );
  }
}

class _SessionStatMini extends StatelessWidget {
  final String label;
  final String value;
  const _SessionStatMini({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SetInput extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final String hint;
  final String suffix;

  const _SetInput({
    required this.controller,
    required this.enabled,
    required this.hint,
    required this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: enabled ? AppColors.surface2 : AppColors.surface3,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: AppColors.textTertiary),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isCollapsed: true,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Text(
              suffix,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
