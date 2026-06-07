import 'package:flutter/material.dart';

class WorkoutPlan {
  final String id;
  final String userId;
  final String name;
  final String goal;
  final String level;
  final int daysPerWeek;
  final String description;
  final bool isActive;
  final List<WorkoutDay> workoutDays;

  WorkoutPlan({
    required this.id,
    required this.userId,
    required this.name,
    required this.goal,
    required this.level,
    required this.daysPerWeek,
    required this.description,
    required this.isActive,
    required this.workoutDays,
  });

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) {
    var list = json['workoutDays'] as List? ?? json['sessions'] as List? ?? [];
    return WorkoutPlan(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      goal: json['goal']?.toString() ?? '',
      level: json['level']?.toString() ?? 'Beginner',
      daysPerWeek: json['daysPerWeek'] is int ? json['daysPerWeek'] : 0,
      description: json['description']?.toString() ?? '',
      isActive: json['isActive'] ?? false,
      workoutDays: list.map((i) => WorkoutDay.fromJson(Map<String, dynamic>.from(i))).toList(),
    );
  }
}

class WorkoutDay {
  final String id;
  final int dayNumber;
  final String weekday;
  final String dayName;
  final String focus;
  final List<String> targetMuscleGroups;
  final List<WorkoutExercise> exercises;

  WorkoutDay({
    required this.id,
    required this.dayNumber,
    required this.weekday,
    required this.dayName,
    required this.focus,
    required this.targetMuscleGroups,
    required this.exercises,
  });

  factory WorkoutDay.fromJson(Map<String, dynamic> json) {
    var list = json['exercises'] as List? ?? [];
    var muscles = json['targetMuscleGroups'] as List? ?? [];
    return WorkoutDay(
      id: json['id']?.toString() ?? '',
      dayNumber: json['dayNumber'] is int ? json['dayNumber'] : 0,
      weekday: json['dayOfWeek']?.toString() ?? json['weekday']?.toString() ?? '',
      dayName: json['dayName']?.toString() ?? json['dayOfWeek']?.toString() ?? '',
      focus: json['focus']?.toString() ?? '',
      targetMuscleGroups: muscles.map((m) => m.toString()).toList(),
      exercises: list.map((i) => WorkoutExercise.fromJson(Map<String, dynamic>.from(i))).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dayOfWeek': weekday,
      'focus': focus.isEmpty ? dayName : focus,
      'exercises': exercises.map((e) => e.toJson()).toList(),
    };
  }
}

class WorkoutExercise {
  final String exerciseId;
  final String exerciseName;
  final int sets;
  final String reps;
  final int restTime;
  final String note;
  final String muscleGroup;

  WorkoutExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
    required this.reps,
    required this.restTime,
    required this.note,
    this.muscleGroup = 'Unknown',
  });

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    return WorkoutExercise(
      exerciseId: json['exerciseId']?.toString() ?? '',
      exerciseName: json['exerciseName']?.toString() ?? '',
      sets: json['sets'] is int ? json['sets'] : 3,
      reps: json['reps']?.toString() ?? '10',
      restTime: json['restTime'] is int ? json['restTime'] : 60,
      note: json['notes']?.toString() ?? json['note']?.toString() ?? '',
      muscleGroup: json['muscleGroup']?.toString() ?? 'Unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'sets': sets,
      'reps': reps,
      'notes': note,
    };
  }
}

class Muscle {
  final String id;
  final String name;
  final String category;

  Muscle({
    required this.id,
    required this.name,
    required this.category,
  });

  factory Muscle.fromJson(Map<String, dynamic> json) {
    return Muscle(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
    );
  }
}

class MuscleImpact {
  final String muscleId;
  final double percentage;
  final String? muscleName;
  final String? category;

  MuscleImpact({
    required this.muscleId,
    required this.percentage,
    this.muscleName,
    this.category,
  });

  factory MuscleImpact.fromJson(Map<String, dynamic> json) {
    return MuscleImpact(
      muscleId: json['muscleId']?.toString() ?? '',
      percentage: (json['impactLevel'] ?? json['percentage'] ?? 0.0).toDouble(),
      muscleName: json['muscleName']?.toString(),
      category: json['category']?.toString(),
    );
  }
}
