import 'package:flutter/material.dart';

class AnimatedMuscleMask extends StatefulWidget {
  final String assetPath;
  final Color tierColor;
  final bool isSelected;
  final double height;
  final VoidCallback onTap;

  const AnimatedMuscleMask({
    required this.assetPath,
    required this.tierColor,
    required this.isSelected,
    required this.height,
    required this.onTap,
  });

  @override
  State<AnimatedMuscleMask> createState() => _AnimatedMuscleMaskState();
}

class _AnimatedMuscleMaskState extends State<AnimatedMuscleMask>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _opacityAnim = Tween<double>(
      begin: 0.2,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.isSelected) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedMuscleMask oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _controller.forward();
    } else if (!widget.isSelected && oldWidget.isSelected) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) {
          if (!widget.isSelected) {
            _controller.forward();
          }
        },
        onExit: (_) {
          if (!widget.isSelected) {
            _controller.reverse();
          }
        },
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnim.value,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Glow background when selected
                  if (widget.isSelected)
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: widget.tierColor.withValues(alpha: 0.3),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  // Colored muscle mask
                  Image.asset(
                    widget.assetPath,
                    height: widget.height,
                    fit: BoxFit.contain,
                    color: widget.tierColor.withValues(
                      alpha: _opacityAnim.value,
                    ),
                    colorBlendMode: BlendMode.srcIn,
                  ),
                  // Animated highlight overlay
                  if (widget.isSelected)
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.1, end: 0.5),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeInOut,
                      builder: (context, value, child) {
                        return Image.asset(
                          widget.assetPath,
                          height: widget.height,
                          fit: BoxFit.contain,
                          color: widget.tierColor.withValues(alpha: value * 0.3),
                          colorBlendMode: BlendMode.screen,
                        );
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
