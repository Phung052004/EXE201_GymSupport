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
  int _selectedDayIndex = 0;
  final List<WorkoutDayData> _dayDataList = [];

  bool _isSaving = false;

  final List<String> _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _nameController.text = 'My Custom Routine';
    _goalController.text = widget.goal;
    _levelController.text = 'Beginner';
    _updateDaysList();
  }

  void _updateDaysList() {
    setState(() {
      if (_dayDataList.length < _daysPerWeek) {
        for (int i = _dayDataList.length; i < _daysPerWeek; i++) {
          _dayDataList.add(
            WorkoutDayData(
              dayNumber: i + 1,
              weekday: _weekdays[i % 7],
              dayName: 'Workout Day ${i + 1}',
            ),
          );
        }
      } else if (_dayDataList.length > _daysPerWeek) {
        _dayDataList.removeRange(_daysPerWeek, _dayDataList.length);
      }
      if (_selectedDayIndex >= _dayDataList.length) {
        _selectedDayIndex = _dayDataList.length - 1;
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
      _showError('Please enter routine name');
      return;
    }

    for (int i = 0; i < _dayDataList.length; i++) {
      final day = _dayDataList[i];
      if (day.dayName.trim().isEmpty) {
        _showError('Please enter name for Day ${i + 1}');
        return;
      }
      if (day.exercises.isEmpty) {
        _showError('Please add at least 1 exercise for ${day.dayName}');
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      final userId = await BackendApi.currentUserId();
      if (userId == null || userId.isEmpty) {
        throw Exception('Please login to save routine');
      }

      // Build payload with sessions and exercises
      final payload = {
        "userId": userId,
        "name": name,
        "goal": _goalController.text.trim(),
        "daysPerWeek": _daysPerWeek,
        "sessions": _dayDataList
            .map(
              (day) => {
                "dayOfWeek": day.weekday,
                "focus": day.dayName.isEmpty ? "Workout Session" : day.dayName,
                "exercises": day.exercises
                    .map(
                      (ex) => {
                        "exerciseId": ex.exerciseId,
                        "exerciseName": ex.exerciseName,
                        "sets": ex.sets,
                        "reps": ex.reps,
                        "notes": ex.note,
                      },
                    )
                    .toList(),
              },
            )
            .toList(),
      };

      await BackendApi.createRoutineWithSessions(payload);
      if (!mounted) return;

      if (widget.onRoutineSaved != null) {
        await widget.onRoutineSaved!();
      } else {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showError('Error saving routine: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Build Routine',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMainInfoCard(),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'WORKOUT DAYS',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        '${_selectedDayIndex + 1}/$_daysPerWeek',
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDayTabs(),
                  const SizedBox(height: 16),
                  if (_dayDataList.isNotEmpty)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      child: KeyedSubtree(
                        key: ValueKey(_selectedDayIndex),
                        child: _buildDayCard(
                          _selectedDayIndex,
                          _dayDataList[_selectedDayIndex],
                        ),
                      ),
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildMainInfoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextFieldModern(
            'ROUTINE NAME',
            _nameController,
            Icons.edit_note_rounded,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildTextFieldModern(
                  'GOAL',
                  _goalController,
                  Icons.flag_rounded,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextFieldModern(
                  'LEVEL',
                  _levelController,
                  Icons.bolt_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDaysDropdownModern(),
        ],
      ),
    );
  }

  Widget _buildDayTabs() {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _dayDataList.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final selected = index == _selectedDayIndex;
          final day = _dayDataList[index];
          return InkWell(
            onTap: () => setState(() => _selectedDayIndex = index),
            borderRadius: BorderRadius.circular(18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 86,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.outline,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: .22),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DAY ${index + 1}',
                    style: TextStyle(
                      color: selected
                          ? AppColors.textDark
                          : AppColors.primaryDark,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          day.weekday.substring(0, 3),
                          style: TextStyle(
                            color: selected
                                ? AppColors.textDark
                                : AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (day.exercises.isNotEmpty)
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.textDark,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextFieldModern(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              icon: Icon(icon, color: AppColors.primary, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDaysDropdownModern() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DAYS PER WEEK',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _daysPerWeek,
                    dropdownColor: AppColors.surface2,
                    isExpanded: true,
                    items: List.generate(7, (i) => i + 1)
                        .map(
                          (d) => DropdownMenuItem(
                            value: d,
                            child: Text(
                              '$d Days',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _daysPerWeek = val);
                        _updateDaysList();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDayCard(int index, WorkoutDayData day) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'DAY ${index + 1}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              DropdownButton<String>(
                value: day.weekday,
                dropdownColor: AppColors.surface2,
                underline: const SizedBox(),
                items: _weekdays
                    .map(
                      (w) => DropdownMenuItem(
                        value: w,
                        child: Text(
                          w,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => day.weekday = v!),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (v) => day.dayName = v,
            controller: TextEditingController(text: day.dayName),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
            decoration: const InputDecoration(
              hintText: 'Add session focus (e.g. Chest)',
              hintStyle: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 4),
          const Divider(color: AppColors.outline),
          const SizedBox(height: 8),
          if (day.exercises.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: const Text(
                  'No exercises added yet.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ...day.exercises
              .asMap()
              .entries
              .map(
                (exEntry) =>
                    _buildExerciseRow(index, exEntry.key, exEntry.value),
              )
              .toList(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => _addExercise(index),
              icon: const Icon(
                Icons.add_circle_outline_rounded,
                size: 20,
                color: AppColors.accent,
              ),
              label: const Text(
                'Add Exercise',
                style: TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: AppColors.accent.withOpacity(0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseRow(int dayIndex, int exIndex, WorkoutExercise ex) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.fitness_center_rounded,
              color: AppColors.textSecondary,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ex.exerciseName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${ex.sets} Sets • ${ex.reps} Reps',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.redAccent,
              size: 18,
            ),
            onPressed: () => _removeExercise(dayIndex, exIndex),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveRoutine,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: AppColors.textDark,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'SAVE ROUTINE',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class WorkoutDayData {
  int dayNumber;
  String weekday;
  String dayName;
  List<WorkoutExercise> exercises = [];

  WorkoutDayData({
    required this.dayNumber,
    required this.weekday,
    required this.dayName,
  });

  Map<String, dynamic> toJson() {
    return {
      "dayNumber": dayNumber,
      "dayOfWeek": weekday,
      "dayName": dayName,
      "focus": dayName.isEmpty ? "Workout Session" : dayName,
      "targetMuscleGroups": exercises
          .map((e) => e.muscleGroup)
          .toSet()
          .toList(),
      "exercises": exercises.map((e) => e.toJson()).toList(),
    };
  }
}
