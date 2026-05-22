import 'package:flutter/material.dart';
// Removed unused import

class HomeStatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const HomeStatCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1C20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}
