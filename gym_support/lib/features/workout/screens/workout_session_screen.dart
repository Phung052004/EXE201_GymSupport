import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gym_support/core/constants/app_colors.dart';
import 'package:gym_support/core/services/backend_api.dart';
import 'package:gym_support/models/workout_models.dart';
import 'workout_summary_screen.dart';

const _figmaLime = Color(0xFFB7FF2A);
const _figmaInk = Color(0xFF172027);
const _figmaPaper = Color(0xFFF7F7F8);
const _figmaMuted = Color(0xFF777C80);

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
  String _timeDisplay = "00:00:00";

  final Map<String, List<bool>> _completedSets = {};
  final Map<String, List<TextEditingController>> _repsControllers = {};
  final Map<String, List<TextEditingController>> _weightControllers = {};

  bool _isSaving = false;
  final Set<String> _savingSets = {};
  int _selectedExerciseIndex = 0;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _timer = Timer.periodic(const Duration(seconds: 1), _updateTime);

    for (var ex in widget.exercises) {
      final completed = widget.initialCompletedSets[ex.exerciseId] ?? const [];
      final reps = widget.initialReps[ex.exerciseId] ?? const [];
      final weights = widget.initialWeights[ex.exerciseId] ?? const [];
      final setCount = [
        ex.sets,
        completed.length,
        reps.length,
        weights.length,
      ].reduce((value, element) => value > element ? value : element);

      _completedSets[ex.exerciseId] = List.generate(
        setCount,
        (index) => index < completed.length ? completed[index] : false,
      );
      _repsControllers[ex.exerciseId] = List.generate(
        setCount,
        (index) => TextEditingController(
          text: index < reps.length ? '${reps[index]}' : _extractReps(ex.reps),
        ),
      );
      _weightControllers[ex.exerciseId] = List.generate(
        setCount,
        (index) => TextEditingController(
          text: index < weights.length ? '${weights[index]}' : '0',
        ),
      );
    }
  }

  String _extractReps(String repsStr) {
    final match = RegExp(r'(\d+)').firstMatch(repsStr);
    return match?.group(1) ?? '10';
  }

  void _updateTime(Timer timer) {
    if (_stopwatch.isRunning) {
      setState(() {
        _timeDisplay = _formatDuration(_stopwatch.elapsed);
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  void dispose() {
    _timer.cancel();
    for (var list in _repsControllers.values) {
      for (var c in list) {
        c.dispose();
      }
    }
    for (var list in _weightControllers.values) {
      for (var c in list) {
        c.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _doneSet(WorkoutExercise ex, int setIndex) async {
    final saveKey = '${ex.exerciseId}:$setIndex';
    if (_savingSets.contains(saveKey)) return;

    final repsText = _repsControllers[ex.exerciseId]![setIndex].text;
    final weightText = _weightControllers[ex.exerciseId]![setIndex].text;

    final reps = int.tryParse(repsText) ?? 0;
    final weight = double.tryParse(weightText) ?? 0.0;
    if (reps <= 0 || weight < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nhập số reps hợp lệ trước khi lưu set.')),
      );
      return;
    }

    setState(() {
      _savingSets.add(saveKey);
    });

    try {
      await BackendApi.saveSetLog(
        logId: widget.logId,
        exerciseId: ex.exerciseId,
        setNumber: setIndex + 1,
        reps: reps,
        weight: weight,
      );
      if (mounted) {
        setState(() {
          _completedSets[ex.exerciseId]![setIndex] = true;
        });
      }
    } catch (e) {
      debugPrint('Error saving set: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể lưu set: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _savingSets.remove(saveKey));
      }
    }
  }

  Future<void> _finishWorkout() async {
    if (_savingSets.isNotEmpty) return;
    final completedSetCount = _completedSets.values.fold<int>(
      0,
      (sum, sets) => sum + sets.where((done) => done).length,
    );
    if (completedSetCount == 0) {
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
              'exercises': widget.exercises
                  .map(
                    (e) => {
                      'name': e.exerciseName,
                      'sets': _completedSets[e.exerciseId]!
                          .where((done) => done)
                          .length,
                    },
                  )
                  .toList(),
            },
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _figmaPaper,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _figmaInk),
          onPressed: () => Navigator.pop(context),
        ),
        foregroundColor: _figmaInk,
        backgroundColor: _figmaPaper,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Workout Session',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: _figmaInk,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer, size: 14, color: Colors.white70),
                const SizedBox(width: 6),
                Text(
                  _timeDisplay.substring(3), // mm:ss
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSessionOverview(),
          if (widget.exercises.length > 1) _buildExerciseTabs(),
          Expanded(
            child: widget.exercises.isEmpty
                ? const Center(
                    child: Text(
                      'No exercises in this session.',
                      style: TextStyle(color: _figmaMuted),
                    ),
                  )
                : SingleChildScrollView(
                    key: ValueKey(_selectedExerciseIndex),
                    padding: const EdgeInsets.only(top: 4),
                    child: _buildExerciseBlock(
                      widget.exercises[_selectedExerciseIndex],
                    ),
                  ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildExerciseTabs() {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        scrollDirection: Axis.horizontal,
        itemCount: widget.exercises.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final exercise = widget.exercises[index];
          final selected = _selectedExerciseIndex == index;
          final sets = _completedSets[exercise.exerciseId] ?? const <bool>[];
          final done = sets.isNotEmpty && sets.every((value) => value);

          return InkWell(
            onTap: () => setState(() => _selectedExerciseIndex = index),
            borderRadius: BorderRadius.circular(18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              constraints: const BoxConstraints(minWidth: 112),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected ? _figmaInk : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? _figmaInk : AppColors.outline,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: done ? _figmaLime : AppColors.surface2,
                      shape: BoxShape.circle,
                    ),
                    child: done
                        ? const Icon(Icons.check, size: 14, color: _figmaInk)
                        : Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: _figmaInk,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 130),
                    child: Text(
                      exercise.exerciseName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? Colors.white : _figmaInk,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
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

  Widget _buildSessionOverview() {
    final totalSets = _completedSets.values.fold<int>(
      0,
      (sum, sets) => sum + sets.length,
    );
    final completedSets = _completedSets.values.fold<int>(
      0,
      (sum, sets) => sum + sets.where((done) => done).length,
    );
    final progress = totalSets == 0 ? 0.0 : completedSets / totalSets;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _figmaInk,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.planName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      [
                        widget.dayName,
                        widget.focus,
                      ].where((value) => value.trim().isNotEmpty).join('  •  '),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _figmaLime,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$completedSets/$totalSets sets',
                  style: const TextStyle(
                    color: _figmaInk,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: 0.07),
              valueColor: const AlwaysStoppedAnimation(_figmaLime),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseBlock(WorkoutExercise ex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_figmaInk, const Color(0xFF2E383F)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _figmaLime.withValues(alpha: 0.55)),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: _figmaLime,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Icon(
                  Icons.fitness_center_rounded,
                  color: _figmaInk,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ex.exerciseName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${ex.sets} sets  •  ${ex.reps} reps  •  ${ex.restTime}s rest',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),
        _buildAiFeedbackBox(),

        const SizedBox(height: 24),
        _buildTableHeader(),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Divider(color: Colors.black12),
        ),

        _buildSectionHeader('SETS'),
        ...List.generate(
          _completedSets[ex.exerciseId]?.length ?? ex.sets,
          (i) => _buildSetRow(ex, i),
        ),

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildAiFeedbackBox() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _figmaLime),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TRAINING TIP',
            style: TextStyle(
              color: _figmaInk,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Ưu tiên kỹ thuật chuẩn. Ghi reps và mức tạ thực tế, sau đó chạm dấu ✓ để lưu set và nhận Muscle XP.',
            style: TextStyle(color: _figmaMuted, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              'SET',
              style: TextStyle(
                color: _figmaMuted,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              'PREV',
              style: TextStyle(
                color: _figmaMuted,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'KG',
                style: TextStyle(
                  color: _figmaMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'REPS',
                style: TextStyle(
                  color: _figmaMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Colors.black12, endIndent: 10)),
          Text(
            title,
            style: const TextStyle(
              color: _figmaMuted,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const Expanded(child: Divider(color: Colors.black12, indent: 10)),
        ],
      ),
    );
  }

  Widget _buildSetRow(
    WorkoutExercise ex,
    int setIndex, {
    bool isWarmup = false,
  }) {
    // Note: To support both warmup and normal sets cleanly, we'd need to adjust state management.
    // For now, I'll use the existing _completedSets but with an offset or just mock the warmup row visual.

    final displayIndex = isWarmup ? 'W${setIndex + 1}' : '${setIndex + 1}';
    final isDone = !isWarmup && _completedSets[ex.exerciseId]![setIndex];
    final isSavingSet = _savingSets.contains('${ex.exerciseId}:$setIndex');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              displayIndex,
              style: const TextStyle(
                color: _figmaInk,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(
            width: 80,
            child: Text(
              '25,0 kgx10',
              style: TextStyle(color: _figmaMuted, fontSize: 12),
            ),
          ),

          Expanded(
            child: _buildCellInput(
              isWarmup
                  ? TextEditingController(text: '37,5')
                  : _weightControllers[ex.exerciseId]![setIndex],
              'kg',
              isDone || isWarmup,
              highlight: isWarmup,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildCellInput(
              isWarmup
                  ? TextEditingController(text: '10')
                  : _repsControllers[ex.exerciseId]![setIndex],
              '',
              isDone || isWarmup,
            ),
          ),

          SizedBox(
            width: 50,
            child: IconButton(
              onPressed: isDone || isWarmup || isSavingSet
                  ? null
                  : () => _doneSet(ex, setIndex),
              icon: isSavingSet
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      isDone || isWarmup
                          ? Icons.check_circle
                          : Icons.check_circle_outline,
                      color: isDone || isWarmup
                          ? (isWarmup ? Colors.black12 : _figmaInk)
                          : Colors.black26,
                      size: 28,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCellInput(
    TextEditingController controller,
    String suffix,
    bool isReadOnly, {
    bool highlight = false,
  }) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: highlight
            ? _figmaLime.withValues(alpha: 0.45)
            : (isReadOnly ? Colors.transparent : const Color(0xFFEEEEF0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        enabled: !isReadOnly,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: highlight ? _figmaInk : (isReadOnly ? _figmaMuted : _figmaInk),
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          suffixText: suffix,
          suffixStyle: const TextStyle(fontSize: 9, color: _figmaMuted),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: _figmaInk,
                side: const BorderSide(color: _figmaInk),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSaving || _savingSets.isNotEmpty
                  ? null
                  : _finishWorkout,
              style: ElevatedButton.styleFrom(
                backgroundColor: _figmaLime,
                foregroundColor: _figmaInk,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Finish Workout'),
            ),
          ),
        ],
      ),
    );
  }
}
