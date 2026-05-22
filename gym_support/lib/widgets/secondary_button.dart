import 'package:flutter/material.dart';

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const SecondaryButton({super.key, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF2B2E38),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
