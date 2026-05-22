import 'package:flutter/material.dart';

class TrainingSchedule {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;

  const TrainingSchedule({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
  });
}
