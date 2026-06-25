import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class LogoutButton extends StatelessWidget {
  final VoidCallback onTap;

  const LogoutButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF3A1F29),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFFF4D6D).withValues(alpha: 0.22),
          ),
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(PhosphorIconsBold.signOut, color: Color(0xFFFF4D6D), size: 19),
              SizedBox(width: 8),
              Text(
                'Log Out',
                style: TextStyle(
                  color: Color(0xFFFF4D6D),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
