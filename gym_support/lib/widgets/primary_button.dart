import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF12E67F), Color(0xFF248DFF)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF12E67F).withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: const Color(0xFF111318), size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  text,
                  style: const TextStyle(
                    color: Color(0xFF111318),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (icon == null) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward,
                    color: Color(0xFF111318),
                    size: 20,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
