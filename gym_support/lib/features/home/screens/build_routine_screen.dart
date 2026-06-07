import 'package:flutter/material.dart';
import 'package:gym_support/core/constants/app_colors.dart';
import 'package:gym_support/core/services/backend_api.dart';
import 'package:gym_support/models/workout_models.dart';
import 'package:gym_support/features/workout/screens/select_exercise_screen.dart';

class BuildRoutineScreen extends StatefulWidget {
  final String goal;
  final String schedule;
  final Future<void> Function()? onRoutineSaved;

  const BuildRoutineScreen({
    super.key,
    required this.goal,
    required this.schedule,
    this.onRoutineSaved,
  });

  @override
  State<BuildRoutineScreen> createState() => _BuildRoutineScreenState();
}

class _BuildRoutineScreenState extends State<BuildRoutineScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _goalController = TextEditingController();
  final TextEditingController _levelController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  
  int _daysPerWeek = 3;
  final List<WorkoutDayData> _dayDataList = [];

  bool _isSaving = false;

  final List<String> _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _nameController.text = 'My Routine';
    _goalController.text = widget.goal;
    _levelController.text = 'Beginner';
    _updateDaysList();
  }

  void _updateDaysList() {
    setState(() {
      if (_dayDataList.length < _daysPerWeek) {
        for (int i = _dayDataList.length; i < _daysPerWeek; i++) {
          _dayDataList.add(WorkoutDayData(
            dayNumber: i + 1,
            weekday: _weekdays[i % 7],
            dayName: 'Day ${i + 1}',
          ));
        }
      } else if (_dayDataList.length > _daysPerWeek) {
        _dayDataList.removeRange(_daysPerWeek, _dayDataList.length);
      }
    });
  }

  Future<void> _addExercise(int dayIndex) async {
    final result = await Navigator.push<WorkoutExercise>(
      context,
      MaterialPageRoute(builder: (_) => const SelectExerciseScreen()),
    );
    if (result != null) {
      setState(() {
        _dayDataList[dayIndex].exercises.add(result);
      });
    }
  }

  void _removeExercise(int dayIndex, int exIndex) {
    setState(() {
      _dayDataList[dayIndex].exercises.removeAt(exIndex);
    });
  }

  Future<void> _saveRoutine() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showError('Vui lòng nhập tên routine');
      return;
    }
    
    for (int i = 0; i < _dayDataList.length; i++) {
      final day = _dayDataList[i];
      if (day.dayName.trim().isEmpty) {
        _showError('Vui lòng nhập tên cho Day ${i + 1}');
        return;
      }
      if (day.exercises.isEmpty) {
        _showError('Vui lòng thêm ít nhất 1 bài tập cho ${day.dayName}');
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      final userId = await BackendApi.currentUserId();
      final payload = {
        "userId": userId,
        "name": name,
        "goal": _goalController.text.trim(),
        "level": _levelController.text.trim(),
        "daysPerWeek": _daysPerWeek,
        "description": _descController.text.trim(),
        "isActive": false,
        "workoutDays": _dayDataList.map((d) => {
          "dayNumber": d.dayNumber,
          "weekday": d.weekday,
          "dayName": d.dayName,
          "targetMuscleGroups": d.exercises.map((e) => "Unknown").toSet().toList(), // Simplification
          "exercises": d.exercises.map((e) => e.toJson()).toList(),
        }).toList(),
      };

      await BackendApi.createWorkoutPlan(payload);
      if (!mounted) return;
      
      if (widget.onRoutineSaved != null) {
        await widget.onRoutineSaved!();
      } else {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showError('Lỗi khi lưu routine: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Build Routine', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMainInfo(),
            const SizedBox(height: 30),
            const Text('Workout Days:', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ..._dayDataList.asMap().entries.map((entry) => _buildDayCard(entry.key, entry.value)).toList(),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveRoutine,
                child: _isSaving 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Save Routine', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMainInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          _buildTextField('Routine Name', _nameController),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildTextField('Goal', _goalController)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField('Level', _levelController)),
            ],
          ),
          const SizedBox(height: 12),
          _buildDaysDropdown(),
          const SizedBox(height: 12),
          _buildTextField('Description', _descController),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
      ),
    );
  }

  Widget _buildDaysDropdown() {
    return Row(
      children: [
        const Text('Days Per Week: ', style: TextStyle(color: Colors.white70)),
        const SizedBox(width: 12),
        DropdownButton<int>(
          value: _daysPerWeek,
          dropdownColor: AppColors.surface,
          items: List.generate(7, (i) => i + 1).map((d) => DropdownMenuItem(
            value: d,
            child: Text('$d days', style: const TextStyle(color: Colors.white)),
          )).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _daysPerWeek = val);
              _updateDaysList();
            }
          },
        ),
      ],
    );
  }

  Widget _buildDayCard(int index, WorkoutDayData day) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Day ${index + 1}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              const Spacer(),
              DropdownButton<String>(
                value: day.weekday,
                dropdownColor: AppColors.surface,
                underline: const SizedBox(),
                items: _weekdays.map((w) => DropdownMenuItem(
                  value: w,
                  child: Text(w, style: const TextStyle(color: Colors.white, fontSize: 14)),
                )).toList(),
                onChanged: (v) => setState(() => day.weekday = v!),
              ),
            ],
          ),
          TextField(
            onChanged: (v) => day.dayName = v,
            controller: TextEditingController(text: day.dayName),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              hintText: 'Day Name (e.g. Chest + Triceps)',
              hintStyle: TextStyle(color: Colors.white24),
              border: InputBorder.none,
            ),
          ),
          const Divider(color: Colors.white10),
          ...day.exercises.asMap().entries.map((exEntry) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(exEntry.value.exerciseName, style: const TextStyle(color: Colors.white, fontSize: 14)),
            subtitle: Text('${exEntry.value.sets} sets x ${exEntry.value.reps}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
              onPressed: () => _removeExercise(index, exEntry.key),
            ),
          )).toList(),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _addExercise(index),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Exercise'),
          ),
        ],
      ),
    );
  }
}

class WorkoutDayData {
  int dayNumber;
  String weekday;
  String dayName;
  List<WorkoutExercise> exercises = [];

  WorkoutDayData({required this.dayNumber, required this.weekday, required this.dayName});
}
