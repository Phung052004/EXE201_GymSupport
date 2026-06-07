import 'package:flutter/material.dart';
import 'package:gym_support/core/constants/app_colors.dart';
import 'package:gym_support/core/services/backend_api.dart';
import 'package:gym_support/models/exercise.dart';
import 'package:gym_support/models/workout_models.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
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
    final setsController = TextEditingController(text: '3');
    final repsController = TextEditingController(text: '10');
    final restController = TextEditingController(text: '60');
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Add ${ex.name}', style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogField('Sets', setsController, TextInputType.number),
              const SizedBox(height: 12),
              _buildDialogField('Reps', repsController, TextInputType.text),
              const SizedBox(height: 12),
              _buildDialogField('Rest Time (sec)', restController, TextInputType.number),
              const SizedBox(height: 12),
              _buildDialogField('Note', noteController, TextInputType.text),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final sets = int.tryParse(setsController.text) ?? 0;
              final reps = repsController.text.trim();
              if (sets <= 0 || reps.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập đủ sets và reps')));
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
            child: const Text('Add to Day'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogField(String label, TextEditingController controller, TextInputType type) {
    return TextField(
      controller: controller,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Select Exercise', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _buildExerciseList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.surface.withOpacity(0.5),
      child: Column(
        children: [
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search exercise...',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.search, color: Colors.white38),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  hint: 'Category',
                  value: _selectedCategory,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Categories')),
                    ..._categories.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))),
                  ],
                  onChanged: (v) => _onCategoryChanged(v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown(
                  hint: 'Muscle',
                  value: _selectedMuscleId,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Muscles')),
                    ..._muscles.map((m) => DropdownMenuItem(value: m['id'].toString(), child: Text(m['name'], overflow: TextOverflow.ellipsis))),
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

  Widget _buildDropdown({required String hint, required dynamic value, required List<DropdownMenuItem<dynamic>> items, required void Function(dynamic) onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<dynamic>(
          value: value,
          hint: Text(hint, style: const TextStyle(color: Colors.white38, fontSize: 13)),
          isExpanded: true,
          dropdownColor: AppColors.surface,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildExerciseList() {
    final filtered = _exercises.where((e) => e.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    if (filtered.isEmpty) {
      return const Center(child: Text('No exercises found', style: TextStyle(color: Colors.white38)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final ex = filtered[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                child: Icon(ex.icon, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ex.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text(ex.muscleGroup, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showAddDialog(ex),
                icon: const Icon(Icons.add_circle, color: AppColors.primary),
              ),
            ],
          ),
        );
      },
    );
  }
}
