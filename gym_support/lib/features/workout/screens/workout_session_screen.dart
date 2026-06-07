import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gym_support/core/constants/app_colors.dart';
import 'package:gym_support/core/services/backend_api.dart';
import 'package:gym_support/models/workout_models.dart';
import 'workout_summary_screen.dart';

class WorkoutSessionScreen extends StatefulWidget {
  final String logId;
  final String planName;
  final String dayName;
  final String focus;
  final List<WorkoutExercise> exercises;

  const WorkoutSessionScreen({
    super.key,
    required this.logId,
    required this.planName,
    required this.dayName,
    required this.focus,
    required this.exercises,
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

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _timer = Timer.periodic(const Duration(seconds: 1), _updateTime);
    
    for (var ex in widget.exercises) {
      _completedSets[ex.exerciseId] = List.generate(ex.sets, (_) => false);
      _repsControllers[ex.exerciseId] = List.generate(
        ex.sets, 
        (_) => TextEditingController(text: _extractReps(ex.reps))
      );
      _weightControllers[ex.exerciseId] = List.generate(
        ex.sets, 
        (_) => TextEditingController(text: '0')
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
      for (var c in list) { c.dispose(); }
    }
    for (var list in _weightControllers.values) {
      for (var c in list) { c.dispose(); }
    }
    super.dispose();
  }

  Future<void> _doneSet(WorkoutExercise ex, int setIndex) async {
    final repsText = _repsControllers[ex.exerciseId]![setIndex].text;
    final weightText = _weightControllers[ex.exerciseId]![setIndex].text;
    
    final reps = int.tryParse(repsText) ?? 0;
    final weight = double.tryParse(weightText) ?? 0.0;
    
    setState(() {
      _completedSets[ex.exerciseId]![setIndex] = true;
    });

    try {
      await BackendApi.saveSetLog(
        logId: widget.logId,
        exerciseId: ex.exerciseId,
        setNumber: setIndex + 1,
        reps: reps,
        weight: weight,
      );
    } catch (e) {
      debugPrint('Error saving set: $e');
    }
  }

  Future<void> _finishWorkout() async {
    setState(() => _isSaving = true);
    try {
      final result = await BackendApi.completeWorkout(email: ''); 
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
                'sets': _completedSets[e.exerciseId]!.where((done) => done).length,
              }).toList(),
            },
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Workout Session', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(_timeDisplay, style: const TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildInfoBanner(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.exercises.length,
              itemBuilder: (context, index) => _buildExerciseBlock(widget.exercises[index]),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.planName, style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
          Text('${widget.dayName} - ${widget.focus}', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildExerciseBlock(WorkoutExercise ex) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(ex.exerciseName, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          ),
          const Divider(color: Colors.white10, height: 1),
          ...List.generate(ex.sets, (i) => _buildSetRow(ex, i)),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildSetRow(WorkoutExercise ex, int setIndex) {
    final isDone = _completedSets[ex.exerciseId]![setIndex];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text('Set ${setIndex + 1}', style: TextStyle(color: isDone ? AppColors.primary : Colors.white60, fontWeight: FontWeight.bold)),
          const Spacer(),
          _buildCompactInput(_repsControllers[ex.exerciseId]![setIndex], 'reps', isDone),
          const SizedBox(width: 10),
          _buildCompactInput(_weightControllers[ex.exerciseId]![setIndex], 'kg', isDone),
          const SizedBox(width: 10),
          IconButton(
            onPressed: isDone ? null : () => _doneSet(ex, setIndex),
            icon: Icon(isDone ? Icons.check_circle : Icons.check_circle_outline, color: isDone ? AppColors.primary : Colors.white24, size: 30),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactInput(TextEditingController controller, String suffix, bool isDone) {
    return Container(
      width: 85, // "ô to 1 xíu"
      height: 44, // "ô to 1 xíu"
      decoration: BoxDecoration(
        color: isDone ? Colors.transparent : AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDone ? AppColors.primary.withOpacity(0.3) : Colors.white12),
      ),
      child: TextField(
        controller: controller,
        enabled: !isDone,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: TextStyle(color: isDone ? AppColors.primary : Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: InputBorder.none,
          hintText: '0',
          hintStyle: const TextStyle(color: Colors.white10),
          suffixText: suffix,
          suffixStyle: const TextStyle(fontSize: 10, color: Colors.white24),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: Colors.white10))),
      child: Row(
        children: [
          Expanded(child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          )),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: ElevatedButton(
            onPressed: _isSaving ? null : _finishWorkout,
            child: _isSaving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Finish Workout'),
          )),
        ],
      ),
    );
  }
}
