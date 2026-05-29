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

  factory Exercise.fromJson(Map<String, dynamic> json) {
    final muscleGroup = json['muscleGroup']?.toString() ?? 'Chest';
    return Exercise(
      id: json['id']?.toString() ?? json['name']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Exercise',
      muscleGroup: muscleGroup,
      setsAndReps: json['setsAndReps']?.toString() ?? '3 sets x 10 reps',
      icon: _iconForMuscle(muscleGroup),
    );
  }

  static IconData _iconForMuscle(String muscleGroup) {
    switch (muscleGroup.toLowerCase()) {
      case 'legs':
        return Icons.accessibility_new;
      case 'back':
        return Icons.fitness_center;
      case 'shoulders':
        return Icons.upload;
      case 'arms':
        return Icons.sports_gymnastics;
      case 'chest':
      default:
        return Icons.fitness_center;
    }
  }
}
