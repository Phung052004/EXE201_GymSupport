import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Custom painter để vẽ progress bar chuyên nghiệp với gradient & glow effect
class MuscleProgressPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color backgroundColor;
  final bool hasGlow;

  MuscleProgressPainter({
    required this.progress,
    required this.primaryColor,
    required this.backgroundColor,
    this.hasGlow = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const radius = 4.0;

    // Background bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(radius)),
      Paint()
        ..color = backgroundColor
        ..style = PaintingStyle.fill,
    );

    // Glow effect nếu đang lớn mạnh
    if (hasGlow && progress > 0) {
      final glowWidth = size.width * progress;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Offset.zero & Size(glowWidth, size.height),
          const Radius.circular(radius),
        ),
        Paint()
          ..color = primaryColor.withValues(alpha: 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 4),
      );
    }

    // Progress bar với gradient
    if (progress > 0) {
      final progressWidth = size.width * progress;
      final gradient = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          primaryColor.withValues(alpha: 0.7),
          primaryColor,
          primaryColor.withValues(alpha: 0.85),
        ],
      ).createShader(Offset.zero & Size(progressWidth, size.height));

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Offset.zero & Size(progressWidth, size.height),
          const Radius.circular(radius),
        ),
        Paint()
          ..shader = gradient
          ..style = PaintingStyle.fill,
      );

      // Highlight edge
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Offset.zero & Size(progressWidth, size.height),
          const Radius.circular(radius),
        ),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(MuscleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.hasGlow != hasGlow;
  }
}

/// Custom widget cho progress bar chuyên nghiệp
class MuscleProgressBar extends StatelessWidget {
  final double value;
  final Color color;
  final Color backgroundColor;
  final double height;
  final bool showGlow;

  const MuscleProgressBar({
    super.key,
    required this.value,
    required this.color,
    this.backgroundColor = const Color(0xFF2A3436),
    this.height = 6,
    this.showGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: MuscleProgressPainter(
        progress: value.clamp(0, 1),
        primaryColor: color,
        backgroundColor: backgroundColor,
        hasGlow: showGlow,
      ),
      size: Size(double.infinity, height),
    );
  }
}

/// Level badge với tier color
class MuscleLevel extends StatelessWidget {
  final int level;
  final Color tierColor;
  final bool isLagging;

  const MuscleLevel({
    super.key,
    required this.level,
    required this.tierColor,
    this.isLagging = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isLagging ? AppColors.danger : tierColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            bgColor.withValues(alpha: 0.15),
            bgColor.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: bgColor.withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bgColor,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            'Lv $level',
            style: TextStyle(
              color: bgColor,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Muscle icon container với gradient background
class MuscleIconContainer extends StatelessWidget {
  final Widget child;
  final Color accentColor;
  final bool isLagging;
  final double size;

  const MuscleIconContainer({
    super.key,
    required this.child,
    required this.accentColor,
    this.isLagging = false,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isLagging ? AppColors.danger : accentColor;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            bgColor.withValues(alpha: 0.15),
            bgColor.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(size / 4),
        border: Border.all(
          color: bgColor.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(child: child),
    );
  }
}
