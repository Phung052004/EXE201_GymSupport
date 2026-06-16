import 'package:flutter/material.dart';

class Exercise {
  final String id;
  final String name;
  final String muscleGroup;
  final String setsAndReps;
  final IconData icon;
  final String equipment;
  final String difficulty;
  final String imageUrl;
  final String videoUrl;
  final String description;
  final String instruction;
  final String safetyNotes;
  final String commonMistakes;
  final String tips;
  final int defaultSets;
  final String defaultReps;
  final int restTimeSeconds;

  const Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.setsAndReps,
    required this.icon,
    this.equipment = '',
    this.difficulty = '',
    this.imageUrl = '',
    this.videoUrl = '',
    this.description = '',
    this.instruction = '',
    this.safetyNotes = '',
    this.commonMistakes = '',
    this.tips = '',
    this.defaultSets = 3,
    this.defaultReps = '10',
    this.restTimeSeconds = 60,
  });

  factory Exercise.fromJson(
    Map<String, dynamic> json, {
    Map<String, Map<String, dynamic>> muscleById = const {},
  }) {
    final impacts = json['muscleImpacts'] as List? ?? const [];
    String muscleGroup =
        json['muscleGroup']?.toString() ??
        json['mainMuscleGroup']?.toString() ??
        'Unknown';
    if (muscleGroup == 'Unknown' &&
        impacts.isNotEmpty &&
        impacts.first is Map) {
      final firstImpact = Map<String, dynamic>.from(impacts.first as Map);
      final muscleId = firstImpact['muscleId']?.toString();
      final muscle = muscleId == null ? null : muscleById[muscleId];
      muscleGroup =
          muscle?['name']?.toString() ??
          muscle?['category']?.toString() ??
          'Unknown';
    }

    final defaultSets = _intValue(
      json['defaultSets'] ?? json['DefaultSets'],
      3,
    );
    final defaultReps =
        (json['defaultReps'] ?? json['DefaultReps'])?.toString() ?? '10';
    return Exercise(
      id: json['id']?.toString() ?? json['name']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Exercise',
      muscleGroup: muscleGroup,
      setsAndReps:
          json['setsAndReps']?.toString() ??
          '$defaultSets sets x $defaultReps reps',
      icon: _iconForMuscle(muscleGroup),
      equipment: (json['equipment'] ?? json['Equipment'])?.toString() ?? '',
      difficulty: (json['difficulty'] ?? json['Difficulty'])?.toString() ?? '',
      imageUrl: (json['imageUrl'] ?? json['ImageUrl'])?.toString() ?? '',
      videoUrl: (json['videoUrl'] ?? json['VideoUrl'])?.toString() ?? '',
      description:
          (json['description'] ?? json['Description'])?.toString() ?? '',
      instruction:
          (json['instruction'] ?? json['Instruction'])?.toString() ?? '',
      safetyNotes:
          (json['safetyNotes'] ?? json['SafetyNotes'])?.toString() ?? '',
      commonMistakes:
          (json['commonMistakes'] ?? json['CommonMistakes'])?.toString() ?? '',
      tips: (json['tips'] ?? json['Tips'])?.toString() ?? '',
      defaultSets: defaultSets,
      defaultReps: defaultReps,
      restTimeSeconds: _intValue(
        json['restTimeSeconds'] ?? json['RestTimeSeconds'],
        60,
      ),
    );
  }

  static int _intValue(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
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
