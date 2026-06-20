import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class HomeHeader extends StatelessWidget {
  final String name;
  final String goal;

  const HomeHeader({super.key, required this.name, required this.goal});

  String _greetingFor(DateTime now) {
    if (now.hour >= 5 && now.hour < 12) {
      return 'Good Morning,';
    }
    if (now.hour < 18) {
      return 'Good Afternoon,';
    }
    if (now.hour < 22) {
      return 'Good Evening,';
    }
    return 'Good Night,';
  }

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
                _greetingFor(DateTime.now()),
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              if (goals.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSelected,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    goals.first.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.surface2,
            shape: BoxShape.circle,
            image: const DecorationImage(
              image: NetworkImage('https://i.pravatar.cc/150?img=32'),
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: AppColors.outline, width: 1),
          ),
        ),
      ],
    );
  }
}
