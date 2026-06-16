import 'package:flutter/material.dart';
import 'package:gym_support/core/constants/app_colors.dart';
import 'package:gym_support/core/services/backend_api.dart';
import 'package:gym_support/models/exercise.dart';
import '../widgets/exercise_picker_card.dart';

class ExerciseSelectionScreen extends StatefulWidget {
  const ExerciseSelectionScreen({super.key});

  @override
  State<ExerciseSelectionScreen> createState() =>
      _ExerciseSelectionScreenState();
}

class _ExerciseSelectionScreenState extends State<ExerciseSelectionScreen> {
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
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi tải dữ liệu: $e')));
    }
  }

  Future<void> _onCategoryChanged(String? category) async {
    if (category == null) return;
    setState(() {
      _selectedCategory = category;
      _selectedMuscleId = null;
      _isLoading = true;
    });
    try {
      final muscles = await BackendApi.getMusclesByCategory(category);
      final exercises = await BackendApi.getExercises(category: category);
      setState(() {
        _muscles = muscles;
        _exercises = exercises;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onMuscleChanged(String? muscleId) async {
    if (muscleId == null) return;
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
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Select Exercises',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
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
              hintText: 'Search Exercise',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.search, color: Colors.white38),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  hint: 'Category',
                  value: _selectedCategory,
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (value) => _onCategoryChanged(value as String?),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown(
                  hint: 'Muscle',
                  value: _selectedMuscleId,
                  items: _muscles
                      .map(
                        (m) => DropdownMenuItem(
                          value: m['id'].toString(),
                          child: Text(m['name']),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => _onMuscleChanged(value as String?),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required dynamic value,
    required List<DropdownMenuItem<dynamic>> items,
    required void Function(dynamic) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<dynamic>(
          value: value,
          hint: Text(
            hint,
            style: const TextStyle(color: Colors.white38, fontSize: 13),
          ),
          isExpanded: true,
          dropdownColor: AppColors.surface,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildExerciseList() {
    final filtered = _exercises
        .where((e) => e.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    if (filtered.isEmpty) {
      return const Center(
        child: Text(
          'Không tìm thấy bài tập phù hợp.',
          style: TextStyle(color: Colors.white38),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final exercise = filtered[index];
        return ExercisePickerCard(
          exercise: exercise,
          actionLabel: 'Select',
          actionIcon: Icons.check_rounded,
          onAction: () => Navigator.pop(context, exercise),
        );
      },
    );
  }
}
