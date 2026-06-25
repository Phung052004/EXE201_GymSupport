import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────────────────────────
  static const Color primary    = Color(0xFF0AB8CF);   // Soft teal-cyan
  static const Color primaryDim = Color(0xFF0892A4);   // Pressed / subdued

  static const Color accent     = Color(0xFFFF6B4A);   // Coral-orange

  // ── Semantic ────────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color danger  = Color(0xFFFF4C4C);
  static const Color warning = Color(0xFFFFAA00);
  static const Color gold    = Color(0xFFFFD700);

  // ── Backgrounds — deep dark teal (not pure black) ───────────────────────────
  static const Color background  = Color(0xFF060E10);
  static const Color surface     = Color(0xFF0D1A1E);
  static const Color surface2    = Color(0xFF142028);
  static const Color surface3    = Color(0xFF1E2E38);
  static const Color surfaceHigh = Color(0xFF2A3E48);

  // ── Borders ─────────────────────────────────────────────────────────────────
  static const Color outline       = Color(0xFF152228);
  static const Color outlineStrong = Color(0xFF1E3040);

  // ── Text ────────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFF0F4F8);
  static const Color textSecondary = Color(0xFF7A9AAA);
  static const Color textTertiary  = Color(0xFF4A6878);
  static const Color textDark      = Color(0xFF060E10);

  // ── Accents ─────────────────────────────────────────────────────────────────
  static const Color violet = Color(0xFF9B7BFF);
  static const Color blue   = Color(0xFF4C9EFF);
  static const Color orange = Color(0xFFFF9F0A);
  static const Color teal   = Color(0xFF2ED9C3);

  // ── Aliases ──────────────────────────────────────────────────────────────────
  static const Color ink             = textPrimary;
  static const Color surfaceSelected = primary;
  static const Color secondaryGreen  = primaryDim;
  static const Color secondary       = violet;
}
