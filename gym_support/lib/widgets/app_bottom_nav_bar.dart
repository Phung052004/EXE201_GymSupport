import 'package:flutter/material.dart';
import 'package:gym_support/core/constants/app_colors.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const AppBottomNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      backgroundColor: AppColors.background,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.white54,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Plan',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.add), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.assessment), label: 'Stats'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
