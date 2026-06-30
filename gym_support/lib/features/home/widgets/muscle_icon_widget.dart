import 'package:flutter/material.dart';
import 'muscle_painters.dart';

/// Widget để vẽ muscle icon dựa vào tên cơ bắp
class MuscleIconPainter extends StatelessWidget {
  final String muscleName;
  final Color color;
  final double size;

  const MuscleIconPainter({
    super.key,
    required this.muscleName,
    required this.color,
    this.size = 24,
  });

  CustomPainter? _getPainter(String name) {
    final lower = name.toLowerCase();

    // Chest
    if (lower.contains('chest') || lower.contains('pectoral') || lower.contains('ngực')) {
      return MuscleChestPainter(color);
    }

    // Abs/Core
    if (lower.contains('abs') || lower.contains('abdom') || lower.contains('bụng') || lower.contains('core')) {
      return MuscleAbsPainter(color);
    }

    // Legs
    if (lower.contains('quad') || lower.contains('quad') || lower.contains('đùi')) {
      return MuscleQuadsPainter(color);
    }

    // Biceps
    if (lower.contains('bicep') || lower.contains('nhị đầu') || lower.contains('tay trước')) {
      return MuscleBicepsPainter(color);
    }

    // Triceps
    if (lower.contains('tricep') || lower.contains('tam đầu') || lower.contains('tay sau')) {
      return MuscleTricepsPainter(color);
    }

    // Lats
    if (lower.contains('lat') || lower.contains('lưng rộng')) {
      return MuscleLatsPainter(color);
    }

    // Glutes
    if (lower.contains('glute') || lower.contains('gluteus') || lower.contains('mông')) {
      return MuscleGlutePainter(color);
    }

    // Shoulders (default to front)
    if (lower.contains('shoulder') || lower.contains('delt') || lower.contains('vai')) {
      return MuscleShoulderPainter(color, isRear: false);
    }

    // Calves
    if (lower.contains('calf') || lower.contains('calves') || lower.contains('bắp chân')) {
      return MuscleCalfPainter(color);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final painter = _getPainter(muscleName);

    if (painter == null) {
      return SizedBox(
        width: size,
        height: size,
        child: Icon(Icons.fitness_center_rounded, size: size * 0.6, color: color),
      );
    }

    return CustomPaint(
      painter: painter,
      size: Size(size, size),
    );
  }
}
