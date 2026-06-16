import 'package:flutter/material.dart';
import 'package:gym_support/core/constants/app_colors.dart';
import 'package:gym_support/core/services/backend_api.dart';
import 'package:gym_support/models/exercise.dart';
import 'package:gym_support/models/workout_models.dart';
import '../widgets/exercise_picker_card.dart';

class SelectExerciseScreen extends StatefulWidget {
  const SelectExerciseScreen({super.key});

  @override
  State<SelectExerciseScreen> createState() => _SelectExerciseScreenState();
}

class _SelectExerciseScreenState extends State<SelectExerciseScreen> {
  List<Exercise> _exercises = [];
  List<String> _categories = [];
  List<Map<String, dynamic>> _muscles = [];

  String? _selectedCategory;
  String? _selectedMuscleId;
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final categories = await BackendApi.getMuscleCategories();
      final exercises = await BackendApi.getExercises();
      setState(() {
        _categories = categories;
        _exercises = exercises;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _onCategoryChanged(String? category) async {
    setState(() {
      _selectedCategory = category;
      _selectedMuscleId = null;
      _isLoading = true;
      _muscles = [];
    });
    try {
      if (category != null) {
        final muscles = await BackendApi.getMusclesByCategory(category);
        final exercises = await BackendApi.getExercises(category: category);
        setState(() {
          _muscles = muscles;
          _exercises = exercises;
        });
      } else {
        final exercises = await BackendApi.getExercises();
        setState(() {
          _exercises = exercises;
        });
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _onMuscleChanged(String? muscleId) async {
    setState(() {
      _selectedMuscleId = muscleId;
      _isLoading = true;
    });
    try {
      final exercises = await BackendApi.getExercises(
        category: _selectedCategory,
        muscleId: muscleId,
      );
      setState(() {
        _exercises = exercises;
      });
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  void _showAddDialog(Exercise ex) {
    final setsController = TextEditingController(text: '${ex.defaultSets}');
    final repsController = TextEditingController(text: ex.defaultReps);
    final restController = TextEditingController(text: '${ex.restTimeSeconds}');
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Add ${ex.name}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildInputModern(
                    'SETS',
                    setsController,
                    TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInputModern(
                    'REPS',
                    repsController,
                    TextInputType.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInputModern(
              'REST TIME (SEC)',
              restController,
              TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildInputModern(
              'NOTE (OPTIONAL)',
              noteController,
              TextInputType.text,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  final sets = int.tryParse(setsController.text) ?? 0;
                  final reps = repsController.text.trim();
                  if (sets <= 0 || reps.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter valid sets and reps'),
                      ),
                    );
                    return;
                  }
                  final workoutEx = WorkoutExercise(
                    exerciseId: ex.id,
                    exerciseName: ex.name,
                    sets: sets,
                    reps: reps,
                    restTime: int.tryParse(restController.text) ?? 60,
                    note: noteController.text.trim(),
                    muscleGroup: ex.muscleGroup,
                  );
                  Navigator.pop(ctx);
                  Navigator.pop(context, workoutEx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'ADD TO DAY',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputModern(
    String label,
    TextEditingController controller,
    TextInputType type,
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
            keyboardType: type,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Select Exercise',
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
          _buildFiltersModern(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  )
                : _buildExerciseListModern(),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersModern() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Search exercise...',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDropdownModern(
                  value: _selectedCategory,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Categories', style: TextStyle(fontSize: 13)),
                    ),
                    ..._categories.map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(
                          c,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                  onChanged: (v) => _onCategoryChanged(v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdownModern(
                  value: _selectedMuscleId,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Muscles', style: TextStyle(fontSize: 13)),
                    ),
                    ..._muscles.map(
                      (m) => DropdownMenuItem(
                        value: m['id'].toString(),
                        child: Text(
                          m['name'],
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                  onChanged: (v) => _onMuscleChanged(v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownModern({
    required dynamic value,
    required List<DropdownMenuItem<dynamic>> items,
    required void Function(dynamic) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<dynamic>(
          value: value,
          dropdownColor: AppColors.surface,
          isExpanded: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildExerciseListModern() {
    final filtered = _exercises
        .where((e) => e.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: AppColors.textSecondary.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            const Text(
              'No exercises found',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final exercise = filtered[index];
        return ExercisePickerCard(
          exercise: exercise,
          actionLabel: 'Add',
          actionIcon: Icons.add_rounded,
          onAction: () => _showAddDialog(exercise),
        );
      },
    );
  }
}
