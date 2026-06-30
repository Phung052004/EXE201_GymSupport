import 'package:flutter/material.dart';

/// Painters để vẽ rank/tier badges chuyên nghiệp
class RankBadgePainter extends CustomPainter {
  final String tier;
  final int level;
  final bool isSelected;

  RankBadgePainter({
    required this.tier,
    required this.level,
    this.isSelected = false,
  });

  Color _getTierColor() {
    switch (tier.toLowerCase()) {
      case 'iron':
        return const Color(0xFF808080);
      case 'bronze':
        return const Color(0xFFCD7F32);
      case 'silver':
        return const Color(0xFFA8A8A8);
      case 'gold':
        return const Color(0xFFFFCC00);
      case 'platinum':
        return const Color(0xFFE2E8F0);
      case 'diamond':
        return const Color(0xFF00D9FF);
      case 'champion':
        return const Color(0xFF9C27B0);
      default:
        return const Color(0xFF555555);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final tierColor = _getTierColor();
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Background circle glow
    if (isSelected) {
      canvas.drawCircle(
        Offset(centerX, centerY),
        size.width * 0.52,
        Paint()
          ..color = tierColor.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8),
      );
    }

    // Main badge circle
    final badgePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          tierColor.withValues(alpha: 0.9),
          tierColor.withValues(alpha: 0.7),
        ],
        center: Alignment.topLeft,
      ).createShader(Rect.fromCircle(center: Offset(centerX, centerY), radius: size.width * 0.45));

    canvas.drawCircle(
      Offset(centerX, centerY),
      size.width * 0.45,
      badgePaint,
    );

    // Tier name arc at top
    final textPainter = TextPainter(
      text: TextSpan(
        text: tier.toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontSize: size.width * 0.12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(centerX - textPainter.width / 2, centerY - size.width * 0.15),
    );

    // Level number at center
    final levelPainter = TextPainter(
      text: TextSpan(
        text: 'Lv$level',
        style: TextStyle(
          color: Colors.white,
          fontSize: size.width * 0.22,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    levelPainter.layout();
    levelPainter.paint(
      canvas,
      Offset(centerX - levelPainter.width / 2, centerY - levelPainter.height / 2),
    );

    // Shine effect
    final shinePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.4),
          Colors.white.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(centerX * 0.7, centerY * 0.7), radius: size.width * 0.3));

    canvas.drawCircle(
      Offset(centerX, centerY),
      size.width * 0.42,
      shinePaint,
    );

    // Border ring
    canvas.drawCircle(
      Offset(centerX, centerY),
      size.width * 0.45,
      Paint()
        ..color = Colors.white.withValues(alpha: isSelected ? 0.6 : 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.5 : 1.5,
    );

    // Inner ring
    canvas.drawCircle(
      Offset(centerX, centerY),
      size.width * 0.38,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(RankBadgePainter oldDelegate) =>
      oldDelegate.tier != tier ||
      oldDelegate.level != level ||
      oldDelegate.isSelected != isSelected;
}

/// Widget to display rank badge
class RankBadge extends StatelessWidget {
  final String tier;
  final int level;
  final bool isSelected;
  final VoidCallback? onTap;
  final double size;

  const RankBadge({
    super.key,
    required this.tier,
    required this.level,
    this.isSelected = false,
    this.onTap,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isSelected ? 1.12 : 1.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.elasticOut,
        child: CustomPaint(
          painter: RankBadgePainter(
            tier: tier,
            level: level,
            isSelected: isSelected,
          ),
          size: Size(size, size),
        ),
      ),
    );
  }
}
