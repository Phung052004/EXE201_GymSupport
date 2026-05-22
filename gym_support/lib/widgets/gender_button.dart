import 'package:flutter/material.dart';

class GenderButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const GenderButton({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 52,
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF12E67F)
                : const Color(0xFF2B2E38),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? const Color(0xFF111318) : Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
