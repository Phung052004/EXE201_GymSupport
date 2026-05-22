import 'package:flutter/material.dart';
import '../models/fitness_goal.dart';

class GoalOptionCard extends StatelessWidget {
  final FitnessGoal goal;
  final bool isSelected;
  final VoidCallback onTap;

  const GoalOptionCard({
    super.key,
    required this.goal,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? goal.color.withValues(alpha: 0.15)
              : const Color(0xFF2B2E38),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? goal.color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? goal.color
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                goal.icon,
                color: isSelected ? const Color(0xFF111318) : Colors.white70,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    goal.subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: goal.color, size: 24),
          ],
        ),
      ),
    );
  }
}
