import 'package:flutter/material.dart';

import 'package:gym_support/core/services/backend_api.dart';
import '../../../models/exercise.dart';
import '../widgets/exercise_header.dart';
import '../widgets/exercise_list_item.dart';
import '../widgets/exercise_search_box.dart';
import '../widgets/muscle_filter_chips.dart';
import '../widgets/scheduling_card.dart';

class ExercisesScreen extends StatefulWidget {
  final String goal;
  final String schedule;
  final Set<String> selectedExerciseIds;
  final ValueChanged<String> onToggleExercise;

  const ExercisesScreen({
    super.key,
    required this.goal,
    required this.schedule,
    required this.selectedExerciseIds,
    required this.onToggleExercise,
  });

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  final TextEditingController searchController = TextEditingController();

  String searchText = '';
  String selectedFilter = 'All';
  bool _loadingCatalog = false;
  String? _catalogError;

  final List<String> filters = const [
    'All',
    'Chest',
    'Legs',
    'Back',
    'Shoulders',
    'Arms',
  ];

  List<Exercise> exercises = const [];

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    setState(() {
      _loadingCatalog = true;
      _catalogError = null;
    });

    try {
      final catalog = await BackendApi.getExercises();
      if (!mounted) return;
      setState(() {
        if (catalog.isNotEmpty) {
          exercises = catalog;
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _catalogError = error.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loadingCatalog = false;
      });
    }
  }

  List<Exercise> get filteredExercises {
    return exercises.where((exercise) {
      final matchesFilter =
          selectedFilter == 'All' || exercise.muscleGroup == selectedFilter;

      final matchesSearch = exercise.name.toLowerCase().contains(
        searchText.toLowerCase(),
      );

      return matchesFilter && matchesSearch;
    }).toList();
  }

  void showAddExerciseMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng thêm bài tập custom sẽ làm sau')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = filteredExercises;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExerciseHeader(
              goal: widget.goal,
              schedule: widget.schedule,
              onAdd: showAddExerciseMessage,
            ),
            const SizedBox(height: 10),
            ExerciseInfoChips(goal: widget.goal, schedule: widget.schedule),
            const SizedBox(height: 16),
            const SchedulingCard(),
            const SizedBox(height: 14),
            ExerciseSearchBox(
              controller: searchController,
              onChanged: (value) {
                setState(() {
                  searchText = value;
                });
              },
            ),
            const SizedBox(height: 14),
            MuscleFilterChips(
              filters: filters,
              selectedFilter: selectedFilter,
              onSelected: (filter) {
                setState(() {
                  selectedFilter = filter;
                });
              },
            ),
            const SizedBox(height: 14),
            if (_loadingCatalog)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_catalogError != null)
              Expanded(
                child: Center(
                  child: Text(
                    'Không tải được bài tập:\n$_catalogError',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: items.isEmpty
                    ? const EmptyExerciseSearchResult()
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 18),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final exercise = items[index];

                          return ExerciseListItem(
                            exercise: exercise,
                            isSelected: widget.selectedExerciseIds.contains(
                              exercise.id,
                            ),
                            onToggle: () {
                              widget.onToggleExercise(exercise.id);
                            },
                          );
                        },
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

class EmptyExerciseSearchResult extends StatelessWidget {
  const EmptyExerciseSearchResult({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Không tìm thấy bài tập phù hợp',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.45),
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
