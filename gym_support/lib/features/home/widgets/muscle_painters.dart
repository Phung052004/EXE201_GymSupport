import 'package:flutter/material.dart';

/// Custom painters để vẽ các muscle groups đẹp
/// Dùng Paint API để tạo anatomically-accurate muscle shapes

class MuscleChestPainter extends CustomPainter {
  final Color color;
  MuscleChestPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    // Left pectoral
    final leftPath = Path()
      ..moveTo(size.width * 0.5, size.height * 0.2)
      ..quadraticBezierTo(size.width * 0.35, size.height * 0.35, size.width * 0.30, size.height * 0.55)
      ..quadraticBezierTo(size.width * 0.28, size.height * 0.65, size.width * 0.32, size.height * 0.75)
      ..quadraticBezierTo(size.width * 0.42, size.height * 0.78, size.width * 0.5, size.height * 0.68)
      ..close();

    canvas.drawPath(leftPath, paint);
    canvas.drawPath(leftPath, highlight);

    // Right pectoral
    final rightPath = Path()
      ..moveTo(size.width * 0.5, size.height * 0.2)
      ..quadraticBezierTo(size.width * 0.65, size.height * 0.35, size.width * 0.70, size.height * 0.55)
      ..quadraticBezierTo(size.width * 0.72, size.height * 0.65, size.width * 0.68, size.height * 0.75)
      ..quadraticBezierTo(size.width * 0.58, size.height * 0.78, size.width * 0.5, size.height * 0.68)
      ..close();

    canvas.drawPath(rightPath, paint);
    canvas.drawPath(rightPath, highlight);

    // Center definition line
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.22),
      Offset(size.width * 0.5, size.height * 0.72),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(MuscleChestPainter oldDelegate) => oldDelegate.color != color;
}

class MuscleAbsPainter extends CustomPainter {
  final Color color;
  MuscleAbsPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    final padding = size.width * 0.15;
    final boxWidth = (size.width - padding * 2 - size.width * 0.05) / 2;
    final boxHeight = size.height * 0.12;

    // 6-pack grid
    final positions = [
      (padding, size.height * 0.35),
      (padding + boxWidth + size.width * 0.05, size.height * 0.35),
      (padding, size.height * 0.50),
      (padding + boxWidth + size.width * 0.05, size.height * 0.50),
      (padding, size.height * 0.65),
      (padding + boxWidth + size.width * 0.05, size.height * 0.65),
    ];

    for (final (x, y) in positions) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, boxWidth, boxHeight),
        Radius.circular(size.width * 0.02),
      );
      canvas.drawRRect(rect, paint);
      canvas.drawRRect(rect, highlight);
    }

    // Ridge lines
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1.5;

    // Vertical center line
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.30),
      Offset(size.width * 0.5, size.height * 0.80),
      linePaint,
    );

    // Horizontal lines
    for (final y in [size.height * 0.48, size.height * 0.63]) {
      canvas.drawLine(
        Offset(padding - size.width * 0.02, y),
        Offset(size.width - padding + size.width * 0.02, y),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(MuscleAbsPainter oldDelegate) => oldDelegate.color != color;
}

class MuscleQuadsPainter extends CustomPainter {
  final Color color;
  MuscleQuadsPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    // Vastus medialis (inner)
    final innerLeftPath = Path()
      ..moveTo(size.width * 0.40, size.height * 0.35)
      ..quadraticBezierTo(size.width * 0.35, size.height * 0.55, size.width * 0.38, size.height * 0.85)
      ..quadraticBezierTo(size.width * 0.48, size.height * 0.92, size.width * 0.52, size.height * 0.88)
      ..quadraticBezierTo(size.width * 0.50, size.height * 0.55, size.width * 0.48, size.height * 0.35)
      ..close();

    // Vastus lateralis (outer)
    final outerRightPath = Path()
      ..moveTo(size.width * 0.60, size.height * 0.35)
      ..quadraticBezierTo(size.width * 0.65, size.height * 0.55, size.width * 0.62, size.height * 0.85)
      ..quadraticBezierTo(size.width * 0.52, size.height * 0.92, size.width * 0.48, size.height * 0.88)
      ..quadraticBezierTo(size.width * 0.50, size.height * 0.55, size.width * 0.52, size.height * 0.35)
      ..close();

    // Rectus femoris (center strip)
    final centerPath = Path()
      ..moveTo(size.width * 0.45, size.height * 0.35)
      ..quadraticBezierTo(size.width * 0.48, size.height * 0.62, size.width * 0.50, size.height * 0.90)
      ..quadraticBezierTo(size.width * 0.52, size.height * 0.62, size.width * 0.55, size.height * 0.35)
      ..close();

    canvas.drawPath(innerLeftPath, paint);
    canvas.drawPath(outerRightPath, paint);
    canvas.drawPath(centerPath, paint);

    // Highlights
    canvas.drawPath(innerLeftPath, highlight);
    canvas.drawPath(outerRightPath, highlight);

    // Quad separation lines
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 1.5;

    canvas.drawLine(
      Offset(size.width * 0.45, size.height * 0.35),
      Offset(size.width * 0.42, size.height * 0.88),
      linePaint,
    );

    canvas.drawLine(
      Offset(size.width * 0.55, size.height * 0.35),
      Offset(size.width * 0.58, size.height * 0.88),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(MuscleQuadsPainter oldDelegate) => oldDelegate.color != color;
}

class MuscleBicepsPainter extends CustomPainter {
  final Color color;
  MuscleBicepsPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width * 0.35, size.height * 0.25)
      ..quadraticBezierTo(size.width * 0.28, size.height * 0.45, size.width * 0.32, size.height * 0.65)
      ..quadraticBezierTo(size.width * 0.38, size.height * 0.78, size.width * 0.48, size.height * 0.75)
      ..quadraticBezierTo(size.width * 0.52, size.height * 0.55, size.width * 0.50, size.height * 0.30)
      ..quadraticBezierTo(size.width * 0.42, size.height * 0.22, size.width * 0.35, size.height * 0.25)
      ..close();

    canvas.drawPath(path, paint);

    // Bicep peak highlight
    final peakHighlight = Path()
      ..moveTo(size.width * 0.38, size.height * 0.35)
      ..quadraticBezierTo(size.width * 0.33, size.height * 0.50, size.width * 0.36, size.height * 0.68)
      ..quadraticBezierTo(size.width * 0.42, size.height * 0.72, size.width * 0.46, size.height * 0.65)
      ..quadraticBezierTo(size.width * 0.44, size.height * 0.45, size.width * 0.42, size.height * 0.35)
      ..close();

    canvas.drawPath(peakHighlight, highlight);

    // Inner peak curve
    final peakPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width * 0.40, size.height * 0.50),
        width: size.width * 0.15,
        height: size.height * 0.30,
      ),
      -1.57,
      3.14,
      false,
      peakPaint,
    );
  }

  @override
  bool shouldRepaint(MuscleBicepsPainter oldDelegate) => oldDelegate.color != color;
}

class MuscleTricepsPainter extends CustomPainter {
  final Color color;
  MuscleTricepsPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width * 0.65, size.height * 0.25)
      ..quadraticBezierTo(size.width * 0.72, size.height * 0.45, size.width * 0.68, size.height * 0.65)
      ..quadraticBezierTo(size.width * 0.62, size.height * 0.78, size.width * 0.52, size.height * 0.75)
      ..quadraticBezierTo(size.width * 0.48, size.height * 0.55, size.width * 0.50, size.height * 0.30)
      ..quadraticBezierTo(size.width * 0.58, size.height * 0.22, size.width * 0.65, size.height * 0.25)
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, highlight);

    // Long head definition
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 1.5;

    canvas.drawLine(
      Offset(size.width * 0.55, size.height * 0.30),
      Offset(size.width * 0.60, size.height * 0.72),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(MuscleTricepsPainter oldDelegate) => oldDelegate.color != color;
}

class MuscleLatsPainter extends CustomPainter {
  final Color color;
  MuscleLatsPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    // Left lat wing
    final leftPath = Path()
      ..moveTo(size.width * 0.5, size.height * 0.2)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.35, size.width * 0.15, size.height * 0.55)
      ..quadraticBezierTo(size.width * 0.12, size.height * 0.70, size.width * 0.20, size.height * 0.82)
      ..quadraticBezierTo(size.width * 0.40, size.height * 0.85, size.width * 0.5, size.height * 0.65)
      ..close();

    // Right lat wing
    final rightPath = Path()
      ..moveTo(size.width * 0.5, size.height * 0.2)
      ..quadraticBezierTo(size.width * 0.75, size.height * 0.35, size.width * 0.85, size.height * 0.55)
      ..quadraticBezierTo(size.width * 0.88, size.height * 0.70, size.width * 0.80, size.height * 0.82)
      ..quadraticBezierTo(size.width * 0.60, size.height * 0.85, size.width * 0.5, size.height * 0.65)
      ..close();

    canvas.drawPath(leftPath, paint);
    canvas.drawPath(rightPath, paint);
    canvas.drawPath(leftPath, highlight);
    canvas.drawPath(rightPath, highlight);

    // Lat striations
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;

    for (int i = 1; i < 4; i++) {
      final factor = i / 4;
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(size.width * 0.5, size.height * 0.5),
          width: size.width * 0.4 * factor,
          height: size.height * 0.5 * factor,
        ),
        -0.5,
        3.14,
        false,
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(MuscleLatsPainter oldDelegate) => oldDelegate.color != color;
}

class MuscleGlutePainter extends CustomPainter {
  final Color color;
  MuscleGlutePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;

    // Left glute
    final leftPath = Path()
      ..moveTo(size.width * 0.35, size.height * 0.25)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.50, size.width * 0.28, size.height * 0.75)
      ..quadraticBezierTo(size.width * 0.42, size.height * 0.80, size.width * 0.48, size.height * 0.70)
      ..quadraticBezierTo(size.width * 0.42, size.height * 0.45, size.width * 0.35, size.height * 0.25)
      ..close();

    // Right glute
    final rightPath = Path()
      ..moveTo(size.width * 0.65, size.height * 0.25)
      ..quadraticBezierTo(size.width * 0.75, size.height * 0.50, size.width * 0.72, size.height * 0.75)
      ..quadraticBezierTo(size.width * 0.58, size.height * 0.80, size.width * 0.52, size.height * 0.70)
      ..quadraticBezierTo(size.width * 0.58, size.height * 0.45, size.width * 0.65, size.height * 0.25)
      ..close();

    canvas.drawPath(leftPath, paint);
    canvas.drawPath(rightPath, paint);
    canvas.drawPath(leftPath, highlight);
    canvas.drawPath(rightPath, highlight);

    // Center cleft
    final cleftPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.08)
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.28),
      Offset(size.width * 0.5, size.height * 0.78),
      cleftPaint,
    );
  }

  @override
  bool shouldRepaint(MuscleGlutePainter oldDelegate) => oldDelegate.color != color;
}

class MuscleShoulderPainter extends CustomPainter {
  final Color color;
  final bool isRear;

  MuscleShoulderPainter(this.color, {this.isRear = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    // Delt roundness
    final path = Path()
      ..moveTo(size.width * 0.25, size.height * 0.30)
      ..quadraticBezierTo(size.width * 0.15, size.height * 0.50, size.width * 0.20, size.height * 0.70)
      ..quadraticBezierTo(size.width * 0.35, size.height * 0.75, size.width * 0.45, size.height * 0.55)
      ..quadraticBezierTo(size.width * 0.40, size.height * 0.35, size.width * 0.25, size.height * 0.30)
      ..close();

    canvas.drawPath(path, paint);

    // Highlight shine
    final shineCircle = Rect.fromCircle(
      center: Offset(size.width * 0.22, size.height * 0.42),
      radius: size.width * 0.08,
    );
    canvas.drawOval(shineCircle, highlight);
  }

  @override
  bool shouldRepaint(MuscleShoulderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.isRear != isRear;
}

class MuscleCalfPainter extends CustomPainter {
  final Color color;
  MuscleCalfPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    // Gastrocnemius bulge
    final leftPath = Path()
      ..moveTo(size.width * 0.35, size.height * 0.20)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.45, size.width * 0.28, size.height * 0.80)
      ..quadraticBezierTo(size.width * 0.38, size.height * 0.90, size.width * 0.45, size.height * 0.85)
      ..quadraticBezierTo(size.width * 0.40, size.height * 0.45, size.width * 0.35, size.height * 0.20)
      ..close();

    final rightPath = Path()
      ..moveTo(size.width * 0.65, size.height * 0.20)
      ..quadraticBezierTo(size.width * 0.75, size.height * 0.45, size.width * 0.72, size.height * 0.80)
      ..quadraticBezierTo(size.width * 0.62, size.height * 0.90, size.width * 0.55, size.height * 0.85)
      ..quadraticBezierTo(size.width * 0.60, size.height * 0.45, size.width * 0.65, size.height * 0.20)
      ..close();

    canvas.drawPath(leftPath, paint);
    canvas.drawPath(rightPath, paint);
    canvas.drawPath(leftPath, highlight);
    canvas.drawPath(rightPath, highlight);

    // Soleus underneath
    final soleusLeft = Rect.fromCenter(
      center: Offset(size.width * 0.38, size.height * 0.72),
      width: size.width * 0.12,
      height: size.height * 0.18,
    );
    canvas.drawOval(soleusLeft, Paint()..color = color.withValues(alpha: 0.7));

    final soleusRight = Rect.fromCenter(
      center: Offset(size.width * 0.62, size.height * 0.72),
      width: size.width * 0.12,
      height: size.height * 0.18,
    );
    canvas.drawOval(soleusRight, Paint()..color = color.withValues(alpha: 0.7));
  }

  @override
  bool shouldRepaint(MuscleCalfPainter oldDelegate) => oldDelegate.color != color;
}
