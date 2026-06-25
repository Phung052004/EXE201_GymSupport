import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  // ── Radius ──────────────────────────────────────────────────────────────────
  static const double radiusXs  = 8;
  static const double radiusSm  = 12;
  static const double radiusMd  = 16;
  static const double radiusLg  = 20;
  static const double radiusXl  = 24;
  static const double radiusXxl = 32;

  // ── Spacing ─────────────────────────────────────────────────────────────────
  static const double spacingXs      = 4;
  static const double spacingSm      = 8;
  static const double spacingMd      = 16;
  static const double spacingLg      = 20;
  static const double spacingXl      = 24;
  static const double spacingXxl     = 32;
  static const double spacingScreenH = 20;

  // ── Text Styles ─────────────────────────────────────────────────────────────
  static const TextStyle displayLarge = TextStyle(
    color: AppColors.textPrimary, fontSize: 36,
    fontWeight: FontWeight.w900, letterSpacing: -1.2, height: 1.05,
  );
  static const TextStyle displayMedium = TextStyle(
    color: AppColors.textPrimary, fontSize: 28,
    fontWeight: FontWeight.w900, letterSpacing: -0.8, height: 1.1,
  );
  static const TextStyle displaySmall = TextStyle(
    color: AppColors.textPrimary, fontSize: 22,
    fontWeight: FontWeight.w900, letterSpacing: -0.5, height: 1.2,
  );
  static const TextStyle headlineMedium = TextStyle(
    color: AppColors.textPrimary, fontSize: 20,
    fontWeight: FontWeight.w800, letterSpacing: -0.3,
  );
  static const TextStyle headlineSmall = TextStyle(
    color: AppColors.textPrimary, fontSize: 17,
    fontWeight: FontWeight.w800, letterSpacing: -0.2,
  );
  static const TextStyle titleLarge = TextStyle(
    color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700,
  );
  static const TextStyle titleMedium = TextStyle(
    color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700,
  );
  static const TextStyle bodyLarge = TextStyle(
    color: AppColors.textPrimary, fontSize: 15,
    fontWeight: FontWeight.w500, height: 1.5,
  );
  static const TextStyle bodyMedium = TextStyle(
    color: AppColors.textSecondary, fontSize: 13,
    fontWeight: FontWeight.w500, height: 1.4,
  );
  static const TextStyle labelLarge = TextStyle(
    color: AppColors.textPrimary, fontSize: 13,
    fontWeight: FontWeight.w700, letterSpacing: 0.3,
  );
  static const TextStyle labelSmall = TextStyle(
    color: AppColors.textSecondary, fontSize: 11,
    fontWeight: FontWeight.w700, letterSpacing: 0.8,
  );
  static const TextStyle caption = TextStyle(
    color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500,
  );

  // ── Card Decorations ─────────────────────────────────────────────────────────
  static BoxDecoration cardDecoration({
    Color? color,
    double radius = radiusMd,
    bool withBorder = true,
    List<BoxShadow>? shadows,
  }) {
    return BoxDecoration(
      color: color ?? AppColors.surface,
      borderRadius: BorderRadius.circular(radius),
      border: withBorder ? Border.all(color: AppColors.outline) : null,
      boxShadow: shadows,
    );
  }

  static BoxDecoration glowCardDecoration({
    Color glowColor = AppColors.primary,
    Color? cardColor,
    double radius = radiusMd,
  }) {
    return BoxDecoration(
      color: cardColor ?? AppColors.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: glowColor.withValues(alpha: 0.35)),
      boxShadow: [
        BoxShadow(
          color: glowColor.withValues(alpha: 0.12),
          blurRadius: 24,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static BoxDecoration primaryCardDecoration({double radius = radiusMd}) {
    return BoxDecoration(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(radius),
    );
  }

  // ── Gradients ────────────────────────────────────────────────────────────────
  static const LinearGradient limeGradient = LinearGradient(
    colors: [Color(0xFFCDFF5A), Color(0xFF85D400)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF1A1A1A), Color(0xFF0D0D0D)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF003D4D), Color(0xFF001820)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyanGradient = LinearGradient(
    colors: [Color(0xFF0AB8CF), Color(0xFF0892A4)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFF6B4A), Color(0xFFFF9F0A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient violetGradient = LinearGradient(
    colors: [Color(0xFF9B7BFF), Color(0xFF6A4FCC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Button Styles ────────────────────────────────────────────────────────────
  static ButtonStyle primaryButtonStyle({double radius = radiusMd, double height = 54}) {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textDark,
      minimumSize: Size(double.infinity, height),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.5),
    );
  }

  static ButtonStyle outlineButtonStyle({double radius = radiusMd}) {
    return OutlinedButton.styleFrom(
      foregroundColor: AppColors.textPrimary,
      minimumSize: const Size(double.infinity, 54),
      side: const BorderSide(color: AppColors.outlineStrong),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
    );
  }

  static ButtonStyle dangerButtonStyle({double radius = radiusMd}) {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.danger,
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 54),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
    );
  }

  // ── Input Decoration ─────────────────────────────────────────────────────────
  static InputDecoration inputDecoration({
    String? hint,
    IconData? prefixIcon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 14),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: AppColors.textSecondary, size: 18)
          : null,
      suffix: suffix,
      filled: true,
      fillColor: AppColors.surface2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: AppColors.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: AppColors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

// ── Reusable Widgets ──────────────────────────────────────────────────────────

class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = AppTheme.radiusMd,
  });
  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.65).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.surface3.withValues(alpha: _anim.value + 0.15),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? buttonLabel;
  final VoidCallback? onButton;
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.buttonLabel,
    this.onButton,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.surface2,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.textTertiary, size: 32),
          ),
          const SizedBox(height: 16),
          Text(title, style: AppTheme.headlineSmall, textAlign: TextAlign.center),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(message!, style: AppTheme.bodyMedium, textAlign: TextAlign.center),
          ],
          if (buttonLabel != null && onButton != null) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: onButton,
                style: AppTheme.primaryButtonStyle(height: 44),
                child: Text(buttonLabel!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AppErrorState extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;
  const AppErrorState({super.key, this.message, this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 48),
          const SizedBox(height: 12),
          Text(
            message ?? 'Đã có lỗi xảy ra',
            style: AppTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: 140,
              child: ElevatedButton(
                onPressed: onRetry,
                style: AppTheme.primaryButtonStyle(height: 42),
                child: const Text('Thử lại'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTheme.headlineSmall),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class AppChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  const AppChip({super.key, required this.label, this.selected = false, this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface2,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.outlineStrong,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.textDark : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
