import 'package:flutter/material.dart';

class MuscleRippleEffect extends StatefulWidget {
  final Color color;
  final VoidCallback onTap;
  final Widget child;
  final double size;

  const MuscleRippleEffect({
    required this.color,
    required this.onTap,
    required this.child,
    this.size = 100,
  });

  @override
  State<MuscleRippleEffect> createState() => _MuscleRippleEffectState();
}

class _MuscleRippleEffectState extends State<MuscleRippleEffect>
    with TickerProviderStateMixin {
  late AnimationController _rippleController;
  late AnimationController _glowController;
  late List<_RippleModel> _ripples;

  @override
  void initState() {
    super.initState();

    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _ripples = [];
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _addRipple() {
    final newRipple = _RippleModel(
      controller: AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      ),
    );

    _ripples.add(newRipple);
    newRipple.controller.forward().then((_) {
      if (mounted) {
        setState(() => _ripples.remove(newRipple));
      }
      newRipple.controller.dispose();
    });

    setState(() {});
  }

  void _handleTap() {
    _addRipple();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Base glow background
            AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                return Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withValues(
                          alpha: 0.3 + _glowController.value * 0.2,
                        ),
                        blurRadius: 12 + _glowController.value * 8,
                        spreadRadius: 2 + _glowController.value * 2,
                      ),
                    ],
                  ),
                );
              },
            ),
            // Child content
            widget.child,
            // Ripple waves
            CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _RipplePainter(
                ripples: _ripples,
                color: widget.color,
                radius: widget.size / 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RippleModel {
  final AnimationController controller;
  late Animation<double> opacity;
  late Animation<double> radius;

  _RippleModel({required this.controller}) {
    opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOut),
    );
    radius = Tween<double>(begin: 0.0, end: 1.5).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOut),
    );
  }
}

class _RipplePainter extends CustomPainter {
  final List<_RippleModel> ripples;
  final Color color;
  final double radius;

  _RipplePainter({
    required this.ripples,
    required this.color,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (final ripple in ripples) {
      final paint = Paint()
        ..color = color.withValues(alpha: ripple.opacity.value * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(
        center,
        radius * ripple.radius.value,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) => true;
}
