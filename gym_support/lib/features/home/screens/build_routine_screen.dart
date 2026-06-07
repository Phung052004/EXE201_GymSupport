import 'package:flutter/material.dart';

import 'package:gym_support/core/constants/app_colors.dart';
import 'package:gym_support/core/services/backend_api.dart';
import 'package:gym_support/models/exercise.dart';

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
  final TextEditingController _searchController = TextEditingController();
  final Map<int, Set<String>> _selectedIdsByDay = {0: <String>{}};

  List<Exercise> _exercises = const [];
  int _daysPerWeek = 3;
  int _activeDayIndex = 0;
  bool _loading = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController.text = 'My Routine';
    _loadExercises();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final exercises = await BackendApi.getExercises();
      if (!mounted) return;
      setState(() {
        _exercises = exercises;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  List<Exercise> get _filteredExercises {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _exercises;
    return _exercises.where((exercise) {
      return exercise.name.toLowerCase().contains(query) ||
          exercise.muscleGroup.toLowerCase().contains(query);
    }).toList();
  }

  Set<String> get _activeSelectedIds {
    return _selectedIdsByDay.putIfAbsent(_activeDayIndex, () => <String>{});
  }

  int get _selectedCount {
    return _selectedIdsByDay.values.fold<int>(
      0,
      (total, ids) => total + ids.length,
    );
  }

  List<int> get _dayExerciseCounts {
    return List.generate(
      _daysPerWeek,
      (index) => _selectedIdsByDay[index]?.length ?? 0,
    );
  }

  List<List<Exercise>> get _selectedExercisesByDay {
    return List.generate(_daysPerWeek, (dayIndex) {
      final ids = _selectedIdsByDay[dayIndex] ?? <String>{};
      return _exercises.where((exercise) => ids.contains(exercise.id)).toList();
    });
  }

  void _toggleExercise(Exercise exercise) {
    setState(() {
      final ids = _activeSelectedIds;
      if (ids.contains(exercise.id)) {
        ids.remove(exercise.id);
      } else {
        ids.add(exercise.id);
      }
    });
  }

  void _changeDaysPerWeek(int value) {
    setState(() {
      _daysPerWeek = value;
      if (_activeDayIndex >= value) {
        _activeDayIndex = value - 1;
      }
      _selectedIdsByDay.removeWhere((dayIndex, _) => dayIndex >= value);
      _selectedIdsByDay.putIfAbsent(_activeDayIndex, () => <String>{});
    });
  }

  Future<void> _saveRoutine() async {
    final selectedExercisesByDay = _selectedExercisesByDay;
    final name = _nameController.text.trim().isEmpty
        ? 'My Routine'
        : _nameController.text.trim();
    final goal = widget.goal.trim().isEmpty ? 'Custom' : widget.goal.trim();

    if (_selectedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chọn ít nhất 1 bài tập để tạo routine')),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await BackendApi.createRoutinePlanByDays(
        name: name,
        goal: goal,
        daysPerWeek: _daysPerWeek,
        exercisesByDay: selectedExercisesByDay,
      );
      if (!mounted) return;
      if (widget.onRoutineSaved != null) {
        setState(() {
          _selectedIdsByDay
            ..clear()
            ..[0] = <String>{};
          _activeDayIndex = 0;
          _searchController.clear();
        });
        await widget.onRoutineSaved!();
      } else {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không lưu được routine: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredExercises;
    final activeSelectedIds = _activeSelectedIds;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Build Routine',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
          child: Column(
            children: [
              _RoutineForm(
                nameController: _nameController,
                searchController: _searchController,
                daysPerWeek: _daysPerWeek,
                selectedCount: _selectedCount,
                schedule: widget.schedule,
                onDaysChanged: _changeDaysPerWeek,
                onSearchChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              _RoutineDaySelector(
                activeDayIndex: _activeDayIndex,
                counts: _dayExerciseCounts,
                onDaySelected: (index) {
                  setState(() {
                    _activeDayIndex = index;
                    _selectedIdsByDay.putIfAbsent(index, () => <String>{});
                  });
                },
              ),
              const SizedBox(height: 14),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? _RoutineEmptyState(
                        icon: Icons.wifi_off_rounded,
                        text: 'Không tải được bài tập:\n$_error',
                      )
                    : items.isEmpty
                    ? const _RoutineEmptyState(
                        icon: Icons.search_off_rounded,
                        text: 'Không tìm thấy bài tập phù hợp',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 10),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final exercise = items[index];
                          final selected = activeSelectedIds.contains(
                            exercise.id,
                          );
                          return _RoutineExerciseTile(
                            exercise: exercise,
                            selected: selected,
                            onTap: () => _toggleExercise(exercise),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _saveRoutine,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline_rounded),
                  label: Text(
                    _saving ? 'Đang lưu...' : 'Save Routine',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
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

class _RoutineDaySelector extends StatelessWidget {
  final int activeDayIndex;
  final List<int> counts;
  final ValueChanged<int> onDaySelected;

  const _RoutineDaySelector({
    required this.activeDayIndex,
    required this.counts,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: counts.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = index == activeDayIndex;
          return ChoiceChip(
            selected: selected,
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.event_available_rounded,
                  size: 16,
                  color: selected
                      ? AppColors.textDark
                      : Colors.white.withValues(alpha: 0.62),
                ),
                const SizedBox(width: 6),
                Text('Day ${index + 1}'),
                const SizedBox(width: 6),
                Text(
                  '${counts[index]}',
                  style: TextStyle(
                    color: selected
                        ? AppColors.textDark.withValues(alpha: 0.72)
                        : AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.surface,
            side: BorderSide(
              color: selected
                  ? AppColors.primary
                  : Colors.white.withValues(alpha: 0.08),
            ),
            labelStyle: TextStyle(
              color: selected ? AppColors.textDark : Colors.white,
              fontWeight: FontWeight.w900,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onSelected: (_) => onDaySelected(index),
          );
        },
      ),
    );
  }
}

class _RoutineForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController searchController;
  final int daysPerWeek;
  final int selectedCount;
  final String schedule;
  final ValueChanged<int> onDaysChanged;
  final ValueChanged<String> onSearchChanged;

  const _RoutineForm({
    required this.nameController,
    required this.searchController,
    required this.daysPerWeek,
    required this.selectedCount,
    required this.schedule,
    required this.onDaysChanged,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          TextField(
            controller: nameController,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration(
              label: 'Routine name',
              icon: Icons.edit_note_rounded,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: daysPerWeek,
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: _inputDecoration(
                    label: 'Days / week',
                    icon: Icons.calendar_month_rounded,
                  ),
                  items: List.generate(7, (index) => index + 1)
                      .map(
                        (day) => DropdownMenuItem<int>(
                          value: day,
                          child: Text('$day ngày'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) onDaysChanged(value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              _SelectedCounter(count: selectedCount),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration(
              label: 'Search exercises',
              icon: Icons.search_rounded,
            ),
          ),
          if (schedule.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.speed_rounded,
                  color: AppColors.primary,
                  size: 17,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    schedule,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
      prefixIcon: Icon(icon, color: AppColors.primary),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.06),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        borderRadius: BorderRadius.circular(14),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.primary),
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}

class _SelectedCounter extends StatelessWidget {
  final int count;

  const _SelectedCounter({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$count',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            'selected',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutineExerciseTile extends StatelessWidget {
  final Exercise exercise;
  final bool selected;
  final VoidCallback onTap;

  const _RoutineExerciseTile({
    required this.exercise,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? AppColors.surfaceSelected : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.8)
                  : Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(exercise.icon, color: AppColors.primary, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${exercise.muscleGroup} • ${exercise.setsAndReps}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.52),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.add_circle_outline_rounded,
                color: selected
                    ? AppColors.primary
                    : Colors.white.withValues(alpha: 0.38),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoutineEmptyState extends StatelessWidget {
  final IconData icon;
  final String text;

  const _RoutineEmptyState({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.24), size: 42),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.48),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
