import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:gym_support/core/constants/app_colors.dart';
import 'package:gym_support/core/constants/app_theme.dart';
import '../../../models/exercise.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final Exercise exercise;
  final VoidCallback? onAdd;
  final String addLabel;

  const ExerciseDetailScreen({
    super.key,
    required this.exercise,
    this.onAdd,
    this.addLabel = 'THÊM VÀO BUỔI TẬP',
  });

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  Exercise get exercise => widget.exercise;

  bool get _showBenchOverlay =>
      exercise.name.trim().toLowerCase() == 'barbell bench press';

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _handleAdd() {
    final cb = widget.onAdd;
    if (cb == null) return;
    Navigator.pop(context);
    WidgetsBinding.instance.addPostFrameCallback((_) => cb());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: widget.onAdd == null ? null : _AddBar(
        label: widget.addLabel,
        onPressed: _handleAdd,
      ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── Hero ──────────────────────────────────────────────────────
              SliverToBoxAdapter(child: _buildHero()),
              // ── Content ───────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -28),
                  child: _buildContent(),
                ),
              ),
            ],
          ),
          // ── Back Button ───────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Material(
                color: AppColors.surface.withValues(alpha: 0.85),
                shape: const CircleBorder(),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(PhosphorIconsBold.arrowLeft,
                      color: AppColors.textPrimary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return SizedBox(
      height: 300,
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, __) => Stack(
          fit: StackFit.expand,
          children: [
            // Image
            Transform.scale(
              scale: _showBenchOverlay ? 1 + (_pulseCtrl.value * 0.015) : 1,
              child: exercise.imageUrl.trim().isEmpty
                  ? _imageFallback()
                  : Image.network(
                      exercise.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imageFallback(),
                    ),
            ),
            // Muscle overlay (bench press only)
            if (_showBenchOverlay)
              IgnorePointer(
                child: CustomPaint(
                  painter: _BenchPressMusclePainter(_pulseCtrl.value),
                ),
              ),
            // Gradient scrim
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x66000000),
                    Colors.transparent,
                    Color(0xCC000000),
                  ],
                  stops: [0, 0.4, 1],
                ),
              ),
            ),
            // Muscle legend (bench press only)
            if (_showBenchOverlay)
              const Positioned(right: 16, bottom: 48, child: _MuscleLegend()),
          ],
        ),
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      color: AppColors.surface2,
      alignment: Alignment.center,
      child: Icon(exercise.icon, size: 80, color: AppColors.primary),
    );
  }

  Widget _buildContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle indicator
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Name + muscle
          Text(exercise.name, style: AppTheme.displaySmall),
          const SizedBox(height: 6),
          Text(exercise.muscleGroup, style: AppTheme.bodyMedium),
          const SizedBox(height: 14),

          // Tags
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              if (exercise.equipment.trim().isNotEmpty)
                _Tag(PhosphorIconsBold.barbell, exercise.equipment,
                    AppColors.orange),
              if (exercise.difficulty.trim().isNotEmpty)
                _Tag(PhosphorIconsBold.gauge, exercise.difficulty,
                    AppColors.violet),
            ],
          ),

          const SizedBox(height: 20),

          // Metrics
          Row(
            children: [
              _Metric(
                icon: PhosphorIconsBold.stack,
                color: AppColors.accent,
                label: 'Sets',
                value: '${exercise.defaultSets}',
              ),
              const SizedBox(width: 10),
              _Metric(
                icon: PhosphorIconsBold.repeat,
                color: AppColors.violet,
                label: 'Reps',
                value: exercise.defaultReps,
              ),
              const SizedBox(width: 10),
              _Metric(
                icon: PhosphorIconsRegular.timer,
                color: AppColors.gold,
                label: 'Nghỉ',
                value: '${exercise.restTimeSeconds}s',
              ),
            ],
          ),

          // Description
          if (exercise.description.trim().isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Text(
                exercise.description,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            ),
          ],

          const SizedBox(height: 28),

          // Guide section header
          Row(
            children: [
              Container(
                width: 4, height: 20,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              const Text('Hướng dẫn thực hiện', style: AppTheme.headlineSmall),
            ],
          ),
          const SizedBox(height: 16),

          _GuideCard(
            step: '01',
            title: 'Cách thực hiện',
            icon: PhosphorIconsBold.listNumbers,
            iconColor: AppColors.primary,
            text: exercise.instruction.trim().isEmpty
                ? 'Chưa có hướng dẫn thực hiện.'
                : exercise.instruction,
          ),
          _GuideCard(
            step: '02',
            title: 'Lưu ý an toàn',
            icon: PhosphorIconsRegular.shieldCheck,
            iconColor: AppColors.success,
            text: exercise.safetyNotes.trim().isEmpty
                ? 'Không có lưu ý an toàn đặc biệt.'
                : exercise.safetyNotes,
          ),
          _GuideCard(
            step: '03',
            title: 'Lỗi thường gặp',
            icon: PhosphorIconsBold.warning,
            iconColor: AppColors.warning,
            text: exercise.commonMistakes.trim().isEmpty
                ? 'Chưa có thông tin lỗi thường gặp.'
                : exercise.commonMistakes,
          ),
          _GuideCard(
            step: '04',
            title: 'Mẹo từ huấn luyện viên',
            icon: PhosphorIconsRegular.lightbulb,
            iconColor: AppColors.blue,
            text: exercise.tips.trim().isEmpty
                ? 'Chưa có mẹo tập luyện.'
                : exercise.tips,
          ),

          const SizedBox(height: 8),

          // Video
          _VideoCard(url: exercise.videoUrl),
        ],
      ),
    );
  }
}

// ── Add Bar ───────────────────────────────────────────────────────────────────

class _AddBar extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _AddBar({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.outline)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textDark,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50)),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
            ),
            icon: const Icon(PhosphorIconsBold.plus, size: 20),
            label: Text(label.toUpperCase()),
          ),
        ),
      ),
    );
  }
}

// ── Tag Pill ──────────────────────────────────────────────────────────────────

class _Tag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Tag(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ── Metric tile ───────────────────────────────────────────────────────────────

class _Metric extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  const _Metric({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: AppTheme.cardDecoration(color: AppColors.surface2),
        child: Column(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15, fontWeight: FontWeight.w900),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(label, style: AppTheme.caption),
          ],
        ),
      ),
    );
  }
}

// ── Guide Card ────────────────────────────────────────────────────────────────

class _GuideCard extends StatefulWidget {
  final String step;
  final String title;
  final IconData icon;
  final Color iconColor;
  final String text;
  const _GuideCard({
    required this.step,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  @override
  State<_GuideCard> createState() => _GuideCardState();
}

class _GuideCardState extends State<_GuideCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: AppTheme.cardDecoration(color: AppColors.surface2),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: widget.iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(widget.icon, color: widget.iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BƯỚC ${widget.step}',
                        style: TextStyle(
                          color: widget.iconColor, fontSize: 9,
                          fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 2),
                      Text(widget.title, style: AppTheme.titleMedium),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(PhosphorIconsBold.caretDown,
                      color: AppColors.textSecondary, size: 22),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              child: _expanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        widget.text,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13, height: 1.55),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Video Card ────────────────────────────────────────────────────────────────

class _VideoCard extends StatelessWidget {
  final String url;
  const _VideoCard({required this.url});

  @override
  Widget build(BuildContext context) {
    final enabled = url.trim().isNotEmpty;
    return GestureDetector(
      onTap: enabled ? () {} : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: enabled ? AppTheme.accentGradient : null,
          color: enabled ? null : AppColors.surface2,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              enabled ? PhosphorIconsBold.playCircle : PhosphorIconsBold.videoCameraSlash,
              color: enabled ? Colors.white : AppColors.textTertiary,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              enabled ? 'XEM VIDEO HƯỚNG DẪN' : 'CHƯA CÓ VIDEO',
              style: TextStyle(
                color: enabled ? Colors.white : AppColors.textTertiary,
                fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Muscle Legend ─────────────────────────────────────────────────────────────

class _MuscleLegend extends StatelessWidget {
  const _MuscleLegend();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LegendDot(Color(0xFFF51B2B), 'Cơ chính'),
          SizedBox(height: 4),
          _LegendDot(Color(0xFFFF7A18), 'Cơ phụ'),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot(this.color, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7, height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

// ── BenchPress Muscle Painter (kept identical) ────────────────────────────────

class _BenchPressMusclePainter extends CustomPainter {
  final double progress;
  const _BenchPressMusclePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final pulse = 0.48 + (progress * 0.34);
    _glowOval(
      canvas,
      Rect.fromCenter(
        center: Offset(size.width * 0.495, size.height * 0.455),
        width: size.width * 0.25,
        height: size.height * 0.145,
      ),
      const Color(0xFFF51B2B),
      pulse,
    );
    _rotatedGlow(canvas,
      center: Offset(size.width * 0.345, size.height * 0.43),
      width: size.width * 0.105,
      height: size.height * 0.19,
      angle: -0.22,
      color: const Color(0xFFFF7A18),
      opacity: pulse * 0.78,
    );
    _rotatedGlow(canvas,
      center: Offset(size.width * 0.625, size.height * 0.465),
      width: size.width * 0.105,
      height: size.height * 0.19,
      angle: 0.28,
      color: const Color(0xFFFF7A18),
      opacity: pulse * 0.78,
    );
  }

  void _rotatedGlow(Canvas canvas, {
    required Offset center,
    required double width,
    required double height,
    required double angle,
    required Color color,
    required double opacity,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    _glowOval(canvas,
      Rect.fromCenter(center: Offset.zero, width: width, height: height),
      color, opacity);
    canvas.restore();
  }

  void _glowOval(Canvas canvas, Rect rect, Color color, double opacity) {
    canvas.drawOval(rect.inflate(5),
      Paint()
        ..color = color.withValues(alpha: opacity * 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16));
    canvas.drawOval(rect,
      Paint()
        ..shader = RadialGradient(colors: [
          color.withValues(alpha: opacity),
          color.withValues(alpha: opacity * 0.5),
          color.withValues(alpha: 0),
        ], stops: const [0, 0.58, 1]).createShader(rect));
  }

  @override
  bool shouldRepaint(covariant _BenchPressMusclePainter old) =>
      old.progress != progress;
}
