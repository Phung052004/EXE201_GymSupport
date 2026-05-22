import 'package:flutter/material.dart';

class InputLabel extends StatelessWidget {
  final String text;

  const InputLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.45),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
