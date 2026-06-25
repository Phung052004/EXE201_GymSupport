import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:gym_support/core/constants/app_colors.dart';
import 'package:gym_support/core/constants/app_theme.dart';
import 'package:gym_support/core/services/backend_api.dart';
import 'package:gym_support/models/exercise.dart';
import 'package:gym_support/models/workout_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/exercise_picker_card.dart';

class SelectExerciseScreen extends StatefulWidget {
  const SelectExerciseScreen({super.key});

  @override
  State<SelectExerciseScreen> createState() => _SelectExerciseScreenState();
}

class _SelectExerciseScreenState extends State<SelectExerciseScreen> {
  static const _categoryKey = 'select_exercise_category';
  static const _muscleKey = 'select_exercise_muscle';
  static const _searchKey = 'select_exercise_search';

  List<Exercise> _exercises = [];
  final TextEditingController _searchController = TextEditingController();
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCategory = prefs.getString(_categoryKey);
      final savedMuscleId = prefs.getString(_muscleKey);
      final savedSearch = prefs.getString(_searchKey) ?? '';

      final categories = await BackendApi.getMuscleCategories();
      final validCategory = categories.contains(savedCategory) ? savedCategory : null;
      final muscles = validCategory == null
          ? <Map<String, dynamic>>[]
          : await BackendApi.getMusclesByCategory(validCategory);
      final validMuscle =
          muscles.any((item) => item['id']?.toString() == savedMuscleId) ? savedMuscleId : null;
      final exercises = await BackendApi.getExercises(category: validCategory, muscleId: validMuscle);

      setState(() {
        _categories = categories;
        _muscles = muscles;
        _selectedCategory = validCategory;
        _selectedMuscleId = validMuscle;
        _searchQuery = savedSearch;
        _searchController.text = savedSearch;
        _exercises = exercises;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Future<void> _onCategoryChanged(String? category) async {
    if (_selectedCategory == category) {
      category = null;
    }
    setState(() {
      _selectedCategory = category;
      _selectedMuscleId = null;
      _isLoading = true;
      _muscles = [];
    });
    final prefs = await SharedPreferences.getInstance();
    if (category == null) {
      await prefs.remove(_categoryKey);
    } else {
      await prefs.setString(_categoryKey, category);
    }
    await prefs.remove(_muscleKey);
    try {
      if (category != null) {
        final muscles = await BackendApi.getMusclesByCategory(category);
        final exercises = await BackendApi.getExercises(category: category);
        setState(() { _muscles = muscles; _exercises = exercises; });
      } else {
        final exercises = await BackendApi.getExercises();
        setState(() => _exercises = exercises);
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _onMuscleChanged(String? muscleId) async {
    if (_selectedMuscleId == muscleId) muscleId = null;
    setState(() { _selectedMuscleId = muscleId; _isLoading = true; });
    final prefs = await SharedPreferences.getInstance();
    if (muscleId == null) {
      await prefs.remove(_muscleKey);
    } else {
      await prefs.setString(_muscleKey, muscleId);
    }
    try {
      final exercises = await BackendApi.getExercises(
        category: _selectedCategory,
        muscleId: muscleId,
      );
      setState(() => _exercises = exercises);
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
        padding: EdgeInsets.fromLTRB(24, 8, 24, MediaQuery.of(ctx).viewInsets.bottom + 28),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20, top: 8),
                decoration: BoxDecoration(
                  color: AppColors.outlineStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Exercise name + muscle group
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(PhosphorIconsBold.barbell, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ex.name, style: AppTheme.titleLarge),
                      if (ex.muscleGroup.isNotEmpty)
                        Text(ex.muscleGroup, style: AppTheme.caption),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(PhosphorIconsBold.x, color: AppColors.textSecondary, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildInputField('SETS', setsController, TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(child: _buildInputField('REPS', repsController, TextInputType.text)),
                const SizedBox(width: 12),
                Expanded(child: _buildInputField('NGHỈ (s)', restController, TextInputType.number)),
              ],
            ),
            const SizedBox(height: 12),
            _buildInputField('GHI CHÚ (tuỳ chọn)', noteController, TextInputType.text),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  final sets = int.tryParse(setsController.text) ?? 0;
                  final reps = repsController.text.trim();
                  if (sets <= 0 || reps.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng nhập sets và reps hợp lệ')),
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
                style: AppTheme.primaryButtonStyle(),
                child: const Text('Thêm vào lịch tập', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController ctrl, TextInputType type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outline),
          ),
          child: TextField(
            controller: ctrl,
            keyboardType: type,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
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
          icon: const Icon(PhosphorIconsBold.caretLeft, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Chọn bài tập', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 17)),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (_selectedCategory != null || _selectedMuscleId != null || _searchQuery.isNotEmpty)
            TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() { _searchQuery = ''; });
                _onCategoryChanged(null);
              },
              child: const Text('Reset', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.outline),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) async {
                  setState(() => _searchQuery = val);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString(_searchKey, val);
                },
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Tìm bài tập...',
                  hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  prefixIcon: Icon(PhosphorIconsBold.magnifyingGlass, color: AppColors.textSecondary, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          // Category chips
          if (_categories.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final cat = _categories[i];
                  final selected = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => _onCategoryChanged(cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: selected ? AppColors.primary : AppColors.outline,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: selected ? AppColors.textDark : AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          // Muscle chips (show when category selected)
          if (_muscles.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _muscles.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final muscle = _muscles[i];
                  final muscleId = muscle['id']?.toString();
                  final selected = _selectedMuscleId == muscleId;
                  return GestureDetector(
                    onTap: () => _onMuscleChanged(muscleId),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withValues(alpha: 0.2)
                            : AppColors.surface2,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: selected ? AppColors.primary : AppColors.outlineStrong,
                        ),
                      ),
                      child: Text(
                        muscle['name']?.toString() ?? '',
                        style: TextStyle(
                          color: selected ? AppColors.primary : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Count
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Text(
                  _isLoading ? 'Đang tải...' : '${_filteredExercises.length} bài tập',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // Exercise list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
                : _filteredExercises.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                        itemCount: _filteredExercises.length,
                        itemBuilder: (_, i) => ExercisePickerCard(
                          exercise: _filteredExercises[i],
                          actionLabel: 'Thêm',
                          actionIcon: PhosphorIconsBold.plus,
                          onAction: () => _showAddDialog(_filteredExercises[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  List<Exercise> get _filteredExercises => _exercises
      .where((e) => e.name.toLowerCase().contains(_searchQuery.toLowerCase()))
      .toList();

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: AppColors.surface2, shape: BoxShape.circle),
            child: const Icon(PhosphorIconsBold.magnifyingGlass, color: AppColors.textTertiary, size: 32),
          ),
          const SizedBox(height: 16),
          const Text(
            'Không tìm thấy bài tập',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Thử tìm kiếm từ khác hoặc chọn nhóm cơ khác',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
