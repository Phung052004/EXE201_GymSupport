import 'package:flutter/material.dart';

import '../../../models/exercise.dart';

const _coral = Color(0xFFF26B7A);
const _ink = Color(0xFF29272D);
const _muted = Color(0xFF8C8991);
const _page = Color(0xFFF1F2F5);

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
  late final AnimationController _pulseController;

  Exercise get exercise => widget.exercise;

  bool get _showBenchPressOverlay =>
      exercise.name.trim().toLowerCase() == 'barbell bench press';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _page,
      bottomNavigationBar: widget.onAdd == null
          ? null
          : _AddBar(label: widget.addLabel, onPressed: _handleAdd),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHero()),
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -22),
                  child: _buildContentSheet(),
                ),
              ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Material(
                color: Colors.white.withValues(alpha: .88),
                shape: const CircleBorder(),
                elevation: 2,
                child: IconButton(
                  tooltip: 'Quay lại',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded, color: _ink),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleAdd() {
    final callback = widget.onAdd;
    if (callback == null) return;
    Navigator.pop(context);
    WidgetsBinding.instance.addPostFrameCallback((_) => callback());
  }

  Widget _buildHero() {
    return SizedBox(
      height: 300,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, _) => Stack(
          fit: StackFit.expand,
          children: [
            Transform.scale(
              scale: _showBenchPressOverlay
                  ? 1 + (_pulseController.value * .015)
                  : 1,
              child: exercise.imageUrl.trim().isEmpty
                  ? _imageFallback()
                  : Image.network(
                      exercise.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _imageFallback(),
                    ),
            ),
            if (_showBenchPressOverlay)
              IgnorePointer(
                child: CustomPaint(
                  painter: _BenchPressMusclePainter(_pulseController.value),
                ),
              ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black12, Colors.transparent, Colors.black26],
                  stops: [0, .55, 1],
                ),
              ),
            ),
            if (_showBenchPressOverlay)
              const Positioned(right: 14, bottom: 34, child: _MuscleLegend()),
          ],
        ),
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      color: const Color(0xFFE8E9EC),
      alignment: Alignment.center,
      child: Icon(exercise.icon, size: 82, color: _coral),
    );
  }

  Widget _buildContentSheet() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 34),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exercise.name,
            style: const TextStyle(
              color: _ink,
              fontSize: 24,
              height: 1.15,
              fontWeight: FontWeight.w900,
              letterSpacing: -.5,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            exercise.muscleGroup,
            style: const TextStyle(
              color: _muted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (exercise.equipment.trim().isNotEmpty)
                _Pill(Icons.fitness_center_rounded, exercise.equipment),
              if (exercise.difficulty.trim().isNotEmpty)
                _Pill(Icons.speed_rounded, exercise.difficulty),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  icon: Icons.layers_rounded,
                  color: _coral,
                  label: 'Sets',
                  value: '${exercise.defaultSets}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Metric(
                  icon: Icons.repeat_rounded,
                  color: Color(0xFF7764E8),
                  label: 'Reps',
                  value: exercise.defaultReps,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Metric(
                  icon: Icons.timer_outlined,
                  color: Color(0xFFF2BC00),
                  label: 'Rest',
                  value: '${exercise.restTimeSeconds}s',
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Divider(height: 1, color: Color(0xFFE9E8EC)),
          const SizedBox(height: 20),
          Text(
            _valueOrFallback(
              exercise.description,
              'Chưa có mô tả cho bài tập này.',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF77737C),
              fontSize: 13,
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle('Hướng dẫn'),
          const SizedBox(height: 14),
          _GuideCard(
            index: '01',
            title: 'Cách thực hiện',
            text: _valueOrFallback(
              exercise.instruction,
              'Chưa có hướng dẫn thực hiện.',
            ),
            icon: Icons.format_list_numbered_rounded,
          ),
          _GuideCard(
            index: '02',
            title: 'Lưu ý an toàn',
            text: _valueOrFallback(
              exercise.safetyNotes,
              'Không có lưu ý an toàn đặc biệt.',
            ),
            icon: Icons.health_and_safety_outlined,
          ),
          _GuideCard(
            index: '03',
            title: 'Lỗi thường gặp',
            text: _valueOrFallback(
              exercise.commonMistakes,
              'Chưa có lỗi thường gặp.',
            ),
            icon: Icons.warning_amber_rounded,
          ),
          _GuideCard(
            index: '04',
            title: 'Mẹo từ huấn luyện viên',
            text: _valueOrFallback(exercise.tips, 'Chưa có mẹo tập luyện.'),
            icon: Icons.lightbulb_outline_rounded,
          ),
          const SizedBox(height: 6),
          _VideoCard(url: exercise.videoUrl),
        ],
      ),
    );
  }

  String _valueOrFallback(String value, String fallback) {
    return value.trim().isEmpty ? fallback : value.trim();
  }
}

class _AddBar extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _AddBar({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(28, 10, 28, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE9E8EC))),
        ),
        child: SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: _coral,
              foregroundColor: Colors.white,
              elevation: 5,
              shadowColor: _coral,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            icon: const Icon(Icons.add_rounded, size: 21),
            label: Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: .25,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Pill(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F4F7),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _coral),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: _ink,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

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
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Icon(icon, color: Colors.white, size: 17),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: const TextStyle(
            color: _coral,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Container(width: 72, height: 2, color: _coral),
      ],
    );
  }
}

class _GuideCard extends StatelessWidget {
  final String index;
  final String title;
  final String text;
  final IconData icon;

  const _GuideCard({
    required this.index,
    required this.title,
    required this.text,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE9E8EC)),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: _coral, size: 25),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BƯỚC $index',
                  style: const TextStyle(
                    color: _coral,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  final String url;

  const _VideoCard({required this.url});

  @override
  Widget build(BuildContext context) {
    final enabled = url.trim().isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: enabled ? _coral : const Color(0xFFE3E2E6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            enabled ? Icons.play_circle_fill_rounded : Icons.videocam_off,
            color: enabled ? Colors.white : _muted,
          ),
          const SizedBox(width: 8),
          Text(
            enabled ? 'XEM VIDEO HƯỚNG DẪN' : 'CHƯA CÓ VIDEO HƯỚNG DẪN',
            style: TextStyle(
              color: enabled ? Colors.white : _muted,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MuscleLegend extends StatelessWidget {
  const _MuscleLegend();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .58),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LegendLine(Color(0xFFF51B2B), 'Cơ chính'),
          SizedBox(height: 4),
          _LegendLine(Color(0xFFFF7A18), 'Cơ phụ'),
        ],
      ),
    );
  }
}

class _LegendLine extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendLine(this.color, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _BenchPressMusclePainter extends CustomPainter {
  final double progress;

  const _BenchPressMusclePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final pulse = .48 + (progress * .34);
    _glowOval(
      canvas,
      Rect.fromCenter(
        center: Offset(size.width * .495, size.height * .455),
        width: size.width * .25,
        height: size.height * .145,
      ),
      const Color(0xFFF51B2B),
      pulse,
    );
    _rotatedGlow(
      canvas,
      center: Offset(size.width * .345, size.height * .43),
      width: size.width * .105,
      height: size.height * .19,
      angle: -.22,
      color: const Color(0xFFFF7A18),
      opacity: pulse * .78,
    );
    _rotatedGlow(
      canvas,
      center: Offset(size.width * .625, size.height * .465),
      width: size.width * .105,
      height: size.height * .19,
      angle: .28,
      color: const Color(0xFFFF7A18),
      opacity: pulse * .78,
    );
  }

  void _rotatedGlow(
    Canvas canvas, {
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
    _glowOval(
      canvas,
      Rect.fromCenter(center: Offset.zero, width: width, height: height),
      color,
      opacity,
    );
    canvas.restore();
  }

  void _glowOval(Canvas canvas, Rect rect, Color color, double opacity) {
    canvas.drawOval(
      rect.inflate(5),
      Paint()
        ..color = color.withValues(alpha: opacity * .4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
    canvas.drawOval(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: opacity * .5),
            color.withValues(alpha: 0),
          ],
          stops: const [0, .58, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _BenchPressMusclePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
