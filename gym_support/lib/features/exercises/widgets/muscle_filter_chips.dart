import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class MuscleFilterChips extends StatelessWidget {
  final List<String> filters;
  final String selectedFilter;
  final ValueChanged<String> onSelected;

  const MuscleFilterChips({
    super.key,
    required this.filters,
    required this.selectedFilter,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedFilter == filter;

          return GestureDetector(
            onTap: () => onSelected(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Center(
                child: Text(
                  filter.toUpperCase(),
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.textDark
                        : Colors.white.withValues(alpha: 0.55),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
