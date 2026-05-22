import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class ExerciseSearchBox extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const ExerciseSearchBox({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: Colors.white.withValues(alpha: 0.32),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.28),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
