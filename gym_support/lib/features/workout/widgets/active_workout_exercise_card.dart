import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/exercise.dart';

class ActiveWorkoutExerciseCard extends StatefulWidget {
  final Exercise exercise;
  final bool isCompleted;
  final VoidCallback onToggleComplete;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const ActiveWorkoutExerciseCard({
    super.key,
    required this.exercise,
    required this.isCompleted,
    required this.onToggleComplete,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  State<ActiveWorkoutExerciseCard> createState() => _ActiveWorkoutExerciseCardState();
}

class _ActiveWorkoutExerciseCardState extends State<ActiveWorkoutExerciseCard> {
  late int setCount;
  late List<bool> completedSets;
  late List<TextEditingController> repsControllers;
  late List<TextEditingController> weightControllers;

  @override
  void initState() {
    super.initState();
    final parts = _parseSetsReps(widget.exercise.setsAndReps);
    setCount = int.tryParse(parts.$1) ?? 3;
    completedSets = List.generate(setCount, (_) => false);
    repsControllers = List.generate(setCount, (_) => TextEditingController(text: parts.$2));
    weightControllers = List.generate(setCount, (_) => TextEditingController(text: '0'));
  }

  @override
  void dispose() {
    for (var c in repsControllers) { c.dispose(); }
    for (var c in weightControllers) { c.dispose(); }
    super.dispose();
  }

  (String, String) _parseSetsReps(String raw) {
    final match = RegExp(r'(\d+)\s*sets?\s*x\s*(\d+)').firstMatch(raw.toLowerCase());
    if (match != null) return (match.group(1) ?? '3', match.group(2) ?? '10');
    return ('3', '10');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: widget.isCompleted
              ? AppColors.primary.withValues(alpha: 0.45)
              : Colors.white.withOpacity(0.05),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                GestureDetector(
                  onTap: widget.onToggleComplete,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 25,
                    height: 25,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isCompleted ? AppColors.primary : Colors.transparent,
                      border: Border.all(
                        color: widget.isCompleted
                            ? AppColors.primary
                            : Colors.white.withValues(alpha: 0.22),
                        width: 2,
                      ),
                    ),
                    child: widget.isCompleted
                        ? const Icon(Icons.check, color: AppColors.textDark, size: 16)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.exercise.name,
                        style: TextStyle(
                          color: widget.isCompleted ? Colors.white.withValues(alpha: 0.45) : Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          decoration: widget.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'TARGET: ${widget.exercise.muscleGroup.toUpperCase()}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.36),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: widget.onRemove,
                  child: Icon(Icons.close_rounded, color: Colors.white.withValues(alpha: 0.28), size: 22),
                ),
              ],
            ),
          ),
          if (!widget.isCompleted) ...[
            const Divider(color: Colors.white10, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: List.generate(setCount, (i) => _buildSetRow(i)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSetRow(int index) {
    final isDone = completedSets[index];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Text('SET ${index + 1}', style: TextStyle(color: isDone ? AppColors.primary : Colors.white24, fontSize: 11, fontWeight: FontWeight.w900)),
          const Spacer(),
          _buildInputBox(repsControllers[index], 'REPS', isDone),
          const SizedBox(width: 10),
          _buildInputBox(weightControllers[index], 'KG', isDone),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => setState(() => completedSets[index] = !completedSets[index]),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone ? AppColors.primary : Colors.transparent,
                border: Border.all(color: isDone ? AppColors.primary : Colors.white24, width: 2),
              ),
              child: isDone ? const Icon(Icons.check, color: AppColors.textDark, size: 16) : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBox(TextEditingController controller, String label, bool isDone) {
    return Container(
      width: 80, // "ô to 1 xíu"
      height: 42, // "ô to 1 xíu"
      decoration: BoxDecoration(
        color: isDone ? Colors.transparent : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDone ? AppColors.primary.withOpacity(0.3) : Colors.transparent),
      ),
      child: TextField(
        controller: controller,
        enabled: !isDone,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: TextStyle(color: isDone ? AppColors.primary : Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: InputBorder.none,
          hintText: '0',
          hintStyle: const TextStyle(color: Colors.white10),
          suffixText: label,
          suffixStyle: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.2), fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class WorkoutBadge extends StatelessWidget {
  final String text;

  const WorkoutBadge({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
