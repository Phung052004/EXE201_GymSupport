import 'package:flutter/material.dart';
import 'package:gym_support/widgets/app_logo.dart';
import 'package:gym_support/core/constants/app_colors.dart';

class HomeHeader extends StatelessWidget {
  final String name;
  final String goal;

  const HomeHeader({super.key, required this.name, required this.goal});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good Morning,',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              goal,
              style: TextStyle(color: AppColors.primary.withValues(alpha: 0.9)),
            ),
          ],
        ),
        const AppLogo(),
      ],
    );
  }
}
