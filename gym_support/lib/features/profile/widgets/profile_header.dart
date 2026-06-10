import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class ProfileHeader extends StatelessWidget {
  final String name;

  const ProfileHeader({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 92,
              height: 92,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipOval(
                child: Container(
                  color: AppColors.surface,
                  child: const Icon(
                    Icons.person,
                    color: AppColors.primary,
                    size: 48,
                  ),
                ),
              ),
            ),
            Positioned(
              right: -2,
              bottom: 4,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 3),
                ),
                child: const Icon(
                  Icons.edit,
                  color: AppColors.textDark,
                  size: 15,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 23,
            fontWeight: FontWeight.w900,
          ),
        ),
        // Subscription plan hidden until API integration is complete
        /*
        const SizedBox(height: 5),
        Text(
          'Free Plan • Joined Jan 2026',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.42),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        */
      ],
    );
  }
}
