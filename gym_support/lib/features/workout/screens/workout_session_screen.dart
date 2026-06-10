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
      backgroundColor: Colors.black, // Darker background
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.expand_more, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer, size: 14, color: Colors.white70),
                const SizedBox(width: 6),
                Text(
                  _timeDisplay.substring(3), // mm:ss
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: widget.exercises.length,
              itemBuilder: (context, index) => _buildExerciseBlock(widget.exercises[index]),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildExerciseBlock(WorkoutExercise ex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Exercise Image Section
        Container(
          height: 250,
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: NetworkImage('https://via.placeholder.com/400x300'), // Replace with actual exercise image if available
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withOpacity(0.3), Colors.transparent, Colors.black],
              ),
            ),
          ),
        ),
        
        // Thumbnails
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: SizedBox(
            height: 60,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (context, i) => Container(
                width: 60,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: i == 2 ? Border.all(color: Colors.orange, width: 2) : null,
                  image: const DecorationImage(
                    image: NetworkImage('https://via.placeholder.com/60'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  ex.exerciseName,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              const Icon(Icons.more_horiz, color: Colors.white70),
            ],
          ),
        ),

        const SizedBox(height: 16),
        _buildAiFeedbackBox(),

        const SizedBox(height: 24),
        _buildTableHeader(),
        
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Divider(color: Colors.white10),
        ),
        
        _buildSectionHeader('WARMUP'),
        ...List.generate(1, (i) => _buildSetRow(ex, i, isWarmup: true)), // Sample 1 warmup set
        
        _buildSectionHeader('SETS'),
        ...List.generate(ex.sets, (i) => _buildSetRow(ex, i)),
        
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildAiFeedbackBox() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1525), // Dark purple-ish
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withOpacity(0.2)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ADJUSTED FOR TODAY',
            style: TextStyle(color: Colors.purpleAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1),
          ),
          SizedBox(height: 8),
          Text(
            "You reported moderate energy, so I've eased weights slightly. Hit your reps clean at 95.0kg and you're right on track.",
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
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
          SizedBox(width: 40, child: Text('SET', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold))),
          SizedBox(width: 80, child: Text('PREV', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold))),
          Expanded(child: Center(child: Text('KG', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)))),
          Expanded(child: Center(child: Text('REPS', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)))),
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
          const Expanded(child: Divider(color: Colors.white10, endIndent: 10)),
          Text(title, style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const Expanded(child: Divider(color: Colors.white10, indent: 10)),
        ],
      ),
    );
  }

  Widget _buildSetRow(WorkoutExercise ex, int setIndex, {bool isWarmup = false}) {
    // Note: To support both warmup and normal sets cleanly, we'd need to adjust state management.
    // For now, I'll use the existing _completedSets but with an offset or just mock the warmup row visual.
    
    final displayIndex = isWarmup ? 'W${setIndex + 1}' : '${setIndex + 1}';
    final isDone = !isWarmup && _completedSets[ex.exerciseId]![setIndex];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(displayIndex, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(
            width: 80,
            child: Text('25,0 kgx10', style: TextStyle(color: Colors.white38, fontSize: 12)),
          ),
          
          Expanded(
            child: _buildCellInput(
              isWarmup ? TextEditingController(text: '37,5') : _weightControllers[ex.exerciseId]![setIndex], 
              'kg', 
              isDone || isWarmup,
              highlight: isWarmup,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildCellInput(
              isWarmup ? TextEditingController(text: '10') : _repsControllers[ex.exerciseId]![setIndex], 
              '', 
              isDone || isWarmup,
            ),
          ),
          
          SizedBox(
            width: 50,
            child: IconButton(
              onPressed: isDone || isWarmup ? null : () => _doneSet(ex, setIndex),
              icon: Icon(
                isDone || isWarmup ? Icons.check_circle : Icons.check_circle_outline, 
                color: isDone || isWarmup ? (isWarmup ? Colors.white12 : Colors.green) : Colors.white12, 
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCellInput(TextEditingController controller, String suffix, bool isReadOnly, {bool highlight = false}) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: highlight ? Colors.green.withOpacity(0.1) : (isReadOnly ? Colors.transparent : Colors.white.withOpacity(0.05)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        enabled: !isReadOnly,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: highlight ? Colors.greenAccent : (isReadOnly ? Colors.white60 : Colors.orangeAccent), 
          fontSize: 14, 
          fontWeight: FontWeight.bold
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          suffixText: suffix,
          suffixStyle: const TextStyle(fontSize: 9, color: Colors.white38),
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
