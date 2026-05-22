import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType keyboardType;
  final String? suffixText;
  final ValueChanged<String>? onChanged;
  final bool readOnly;

  const AppTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.keyboardType = TextInputType.text,
    this.suffixText,
    this.onChanged,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      readOnly: readOnly,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        suffixText: suffixText,
        suffixStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.45),
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
        filled: true,
        fillColor: const Color(0xFF2B2E38),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
