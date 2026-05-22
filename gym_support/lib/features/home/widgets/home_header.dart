import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class HomeHeader extends StatelessWidget {
  final String name;
  final String goal;

  const HomeHeader({super.key, required this.name, required this.goal});

  @override
  Widget build(BuildContext context) {
    final goals = goal
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good Morning,',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: goals.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: Icon(
                            Icons.bolt,
                            color: AppColors.primary,
                            size: 15,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        Container(
          width: 54,
          height: 54,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 20,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipOval(
            child: Container(
              color: AppColors.surface,
              child: const Icon(
                Icons.person,
                color: AppColors.primary,
                size: 30,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
