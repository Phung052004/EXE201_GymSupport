import 'package:flutter/material.dart';

class Exercise {
  final String id;
  final String name;
  final String muscleGroup;
  final String setsAndReps;
  final IconData icon;

  const Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.setsAndReps,
    required this.icon,
  });
}
