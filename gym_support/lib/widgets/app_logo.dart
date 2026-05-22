import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF12E67F), Color(0xFF248DFF)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF12E67F).withValues(alpha: 0.35),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(
        Icons.fitness_center,
        color: Color(0xFF111318),
        size: 30,
      ),
    );
  }
}
