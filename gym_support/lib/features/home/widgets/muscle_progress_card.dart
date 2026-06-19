import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../screens/muscle_detail_screen.dart';

class MuscleProgressGrid extends StatelessWidget {
  final List<MuscleProgressData> items;
  final bool isLoading;

  const MuscleProgressGrid({
    super.key,
    required this.items,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 220,
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.outline),
        ),
        child: Text(
          'Complete your first workout to start tracking your muscle progress.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1.5,
          ),
        ),
      );
    }

    final lagging = items
        .where((item) => item.isLagging && item.totalExp > 0)
        .take(4)
        .toList();
    final weakest = items.take(4).toList();
    final priority = lagging.isNotEmpty ? lagging : weakest;

    return Column(
      children: [
        MuscleBalanceMap(items: items),
        const SizedBox(height: 14),
        _PriorityMuscles(items: priority),
      ],
    );
  }
}

class MuscleBalanceMap extends StatefulWidget {
  final List<MuscleProgressData> items;

  const MuscleBalanceMap({super.key, required this.items});

  @override
  State<MuscleBalanceMap> createState() => _MuscleBalanceMapState();
}

class _MuscleBalanceMapState extends State<MuscleBalanceMap> {
  bool _showBack = false;

  @override
  Widget build(BuildContext context) {
    // final byName = {
    //   for (final item in widget.items) _normalize(item.name): item,
    // };

    // MuscleProgressData? find(List<String> keys) {
    //   for (final key in keys) {
    //     final value = byName[_normalize(key)];
    //     if (value != null) return value;
    //   }
    //   return null;
    // }
    MuscleProgressData? find(List<String> keys) {
      final normalizedKeys = keys.map(_normalize).toList();

      // 1. Tìm tất cả các nhóm cơ có Tên hoặc Category chứa từ khóa
      final matches = widget.items.where((item) {
        final normName = _normalize(item.name);
        final normCat = _normalize(item.category);

        return normalizedKeys.any(
          (key) => normName.contains(key) || normCat.contains(key),
        );
      }).toList();

      if (matches.isEmpty) return null;

      // 2. Nếu có nhiều nhóm cơ con (VD: Ngực trên, Ngực giữa),
      // ưu tiên lấy nhóm cơ có EXP cao nhất để đại diện phủ màu
      matches.sort((a, b) => b.totalExp.compareTo(a.totalExp));
      return matches.first;
    }

    // --- 1. Nhóm Gom Cụm ---
    final chest = find(['Ngực', 'Chest']);
    final biceps = find(['Tay trước', 'Biceps']);
    final triceps = find(['Tay sau', 'Triceps']);
    final quads = find(['Đùi trước', 'Quadriceps', 'Quads']);
    final hamstrings = find(['Đùi sau', 'Hamstrings']);
    final glute = find(['Mông', 'Glute']);

    // --- 2. Nhóm Vai ---
    final vaiTruoc = find(['Vai trước', 'Anterior Deltoid']);
    final vaiGiua = find(['Vai giữa', 'Lateral Deltoid']);
    final vaiSau = find(['Vai sau', 'Posterior Deltoid']);

    // --- 3. Nhóm Bụng (ĐÃ THÊM CORE) ---
    final abs = find(['Cơ thẳng bụng', 'Rectus Abdominis', 'Abs']);
    final obliques = find(['Cơ liên sườn', 'Obliques']);
    final core = find([
      'Cơ bụng ngang',
      'Cơ cốt lõi',
      'Core',
      'Cơ lõi',
    ]); // <-- Thêm dòng này

    // --- 4. Nhóm Lưng ---
    final traps = find(['Cầu vai', 'Trapezius', 'Traps']);
    final lats = find(['Lưng xô', 'Latissimus Dorsi', 'Lats']);
    final rhomboids = find(['Lưng giữa', 'Rhomboids']);
    final lowerBack = find(['Dựng cột sống', 'Lower back', 'Erector']);

    // --- 5. Bắp chân ---
    final calvesData = find(['Bắp chân', 'Calves']);

    final activeCount = widget.items.where((item) => item.totalExp > 0).length;
    final weakCount = widget.items.where((item) => item.isLagging).length;

    final displayedMuscles = _showBack
        ? _BodyMuscles(
            triceps: triceps,
            hamstrings: hamstrings,
            glute: glute,
            shouldersPosterior: vaiSau,
            shouldersLateral: vaiGiua,
            traps: traps,
            lats: lats,
            rhomboids: rhomboids,
            lowerBack: lowerBack,
            calvesBack: calvesData,
          )
        : _BodyMuscles(
            chest: chest,
            biceps: biceps,
            quads: quads,
            shouldersAnterior: vaiTruoc,
            shouldersLateral: vaiGiua,
            abs: abs,
            obliques: obliques,
            core: core, // <-- Truyền core vào đây
            calvesFront: calvesData,
          );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1D2527),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _TopMetric(
                  value: '$weakCount',
                  label: 'WEAK MUSCLE\nGROUPS',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _TopMetric(
                  value: '$activeCount',
                  label: 'ACTIVE MUSCLE\nGROUPS',
                  alignEnd: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _BodySideSelector(
            showBack: _showBack,
            onChanged: (value) => setState(() => _showBack = value),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 390,
            child: Center(
              child: _BodyFigure(isBack: _showBack, muscles: displayedMuscles),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Highlighted muscles are the groups gaining or needing attention.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MuscleDetailScreen(items: widget.items),
                  ),
                );
              },
              icon: const Icon(Icons.arrow_forward_ios, size: 14),
              label: const Text('Details'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textDark,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _normalize(String value) {
    final lower = value.toLowerCase();
    final folded = lower
        .replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
        .replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e')
        .replaceAll(RegExp(r'[ìíịỉĩ]'), 'i')
        .replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
        .replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u')
        .replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y')
        .replaceAll('đ', 'd');

    return folded.replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}

class _BodySideSelector extends StatelessWidget {
  final bool showBack;
  final ValueChanged<bool> onChanged;

  const _BodySideSelector({required this.showBack, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [_sideButton('Front', false), _sideButton('Back', true)],
      ),
    );
  }

  Widget _sideButton(String label, bool value) {
    final selected = showBack == value;
    return Tooltip(
      message: 'View ${label.toLowerCase()} muscle groups',
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.textDark : AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _TopMetric extends StatelessWidget {
  final String value;
  final String label;
  final bool alignEnd;

  const _TopMetric({
    required this.value,
    required this.label,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          textAlign: alignEnd ? TextAlign.right : TextAlign.left,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 9,
            fontWeight: FontWeight.w900,
            height: 1.15,
          ),
        ),
      ],
    );
  }
}

class _BodyMuscles {
  // Các nhóm cơ chung/gom cụm
  final MuscleProgressData? chest;
  final MuscleProgressData? biceps;
  final MuscleProgressData? triceps;
  final MuscleProgressData? quads;
  final MuscleProgressData? hamstrings;
  final MuscleProgressData? glute;

  // Vai (Chia nhỏ)
  final MuscleProgressData? shouldersAnterior;
  final MuscleProgressData? shouldersLateral;
  final MuscleProgressData? shouldersPosterior;

  // Bụng/Core (Chia nhỏ) 👇 ĐÃ THÊM CORE
  final MuscleProgressData? abs; // Cơ thẳng bụng
  final MuscleProgressData? obliques; // Cơ liên sườn
  final MuscleProgressData? core; // Cơ cốt lõi / Cơ bụng ngang

  // Lưng (Chia nhỏ)
  final MuscleProgressData? traps;
  final MuscleProgressData? lats;
  final MuscleProgressData? rhomboids;
  final MuscleProgressData? lowerBack;

  // Bắp chân (Chia 2 mặt)
  final MuscleProgressData? calvesFront;
  final MuscleProgressData? calvesBack;

  const _BodyMuscles({
    this.chest,
    this.biceps,
    this.triceps,
    this.quads,
    this.hamstrings,
    this.glute,
    this.shouldersAnterior,
    this.shouldersLateral,
    this.shouldersPosterior,
    this.abs,
    this.obliques,
    this.core, // <-- Thêm vào đây
    this.traps,
    this.lats,
    this.rhomboids,
    this.lowerBack,
    this.calvesFront,
    this.calvesBack,
  });

  // Cầu nối giữ tương thích với CustomPainter cũ
  MuscleProgressData? get shoulders =>
      shouldersAnterior ?? shouldersLateral ?? shouldersPosterior;
  MuscleProgressData? get hips => glute;
  MuscleProgressData? get leftArm => biceps ?? triceps;
  MuscleProgressData? get rightArm => biceps ?? triceps;
  MuscleProgressData? get leftLeg =>
      quads ?? hamstrings ?? calvesFront ?? calvesBack;
  MuscleProgressData? get rightLeg =>
      quads ?? hamstrings ?? calvesFront ?? calvesBack;
  MuscleProgressData? get calves => calvesFront ?? calvesBack;
}

class _BodyFigure extends StatelessWidget {
  final bool isBack;
  final _BodyMuscles muscles;

  const _BodyFigure({required this.isBack, required this.muscles});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Tooltip(
        message:
            '${isBack ? 'Back' : 'Front'} muscle map. Highlighted areas use your real muscle EXP.',
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              isBack
                  ? 'assets/body/body_back.png'
                  : 'assets/body/body_front.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
            ..._maskLayers(),
          ],
        ),
      ),
    );
  }

  List<Widget> _maskLayers() {
    final side = isBack ? 'back' : 'front';

    final entries = isBack
        ? <(String, MuscleProgressData?)>[
            ('triceps', muscles.triceps),
            ('hamstrings', muscles.hamstrings),
            ('glute', muscles.glute),
            ('shoulders_posterior', muscles.shouldersPosterior),
            ('shoulders_lateral', muscles.shouldersLateral),
            ('traps', muscles.traps),
            ('lats', muscles.lats),
            ('rhomboids', muscles.rhomboids),
            ('lower_back', muscles.lowerBack),
            ('calves', muscles.calvesBack),
          ]
        : <(String, MuscleProgressData?)>[
            ('chest', muscles.chest),
            ('biceps', muscles.biceps),
            ('quads', muscles.quads),
            ('shoulders_anterior', muscles.shouldersAnterior),
            ('shoulders_lateral', muscles.shouldersLateral),
            ('abs', muscles.abs),
            ('obliques', muscles.obliques),
            (
              'core',
              muscles.core,
            ), // <-- Thêm dòng này để nạp file front_core.png
            ('calves', muscles.calvesFront),
          ];

    return entries
        .where((entry) => entry.$2 != null && entry.$2!.totalExp > 0)
        .map(
          (entry) => IgnorePointer(
            child: Image.asset(
              'assets/body/masks/${side}_${entry.$1}.png',
              fit: BoxFit.contain,
              color: _figureColor(
                entry.$2,
              ).withValues(alpha: entry.$2!.isLagging ? 0.94 : 0.86),
              colorBlendMode: BlendMode.srcIn,
              filterQuality: FilterQuality.high,
            ),
          ),
        )
        .toList(growable: false);
  }
}

// Kept as a code-only fallback while the mask assets are rolled out.
// ignore: unused_element
class _MuscleFigurePainter extends CustomPainter {
  final _BodyMuscles muscles;
  final bool isBack;

  const _MuscleFigurePainter({required this.muscles, required this.isBack});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 124, size.height / 286);
    final dx = (size.width - 124 * scale) / 2;
    final dy = (size.height - 286 * scale) / 2;

    Offset p(double x, double y) => Offset(dx + x * scale, dy + y * scale);

    void draw(Path path, MuscleProgressData? data, {double alpha = 0.9}) {
      if (data == null || data.totalExp <= 0) return;
      final color = _figureColor(data);
      final fill = Paint()
        ..style = PaintingStyle.fill
        ..color = color.withValues(alpha: alpha);
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = data.isLagging ? 2.0 * scale : 1.15 * scale
        ..color = data.isLagging
            ? const Color(0xFFFF6D65)
            : const Color(0xFFEAF1EF).withValues(alpha: 0.78);

      canvas.drawPath(path, fill);
      canvas.drawPath(path, stroke);
    }

    Path oval(double left, double top, double right, double bottom) {
      return Path()..addOval(
        Rect.fromLTRB(
          p(left, top).dx,
          p(left, top).dy,
          p(right, bottom).dx,
          p(right, bottom).dy,
        ),
      );
    }

    Path path(List<Offset> points) {
      final result = Path()..moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        result.lineTo(points[i].dx, points[i].dy);
      }
      return result..close();
    }

    Path curve(List<Offset> points) {
      final result = Path()..moveTo(points[0].dx, points[0].dy);
      for (var i = 1; i + 2 < points.length; i += 3) {
        result.cubicTo(
          points[i].dx,
          points[i].dy,
          points[i + 1].dx,
          points[i + 1].dy,
          points[i + 2].dx,
          points[i + 2].dy,
        );
      }
      return result..close();
    }

    draw(oval(48, 0, 76, 31), null, alpha: 0.58);
    draw(path([p(52, 28), p(72, 28), p(78, 47), p(46, 47)]), null, alpha: 0.45);

    if (isBack) {
      _drawBack(canvas, p, draw, curve, path);
    } else {
      _drawFront(canvas, p, draw, curve, path);
    }
  }

  void _drawFront(
    Canvas canvas,
    Offset Function(double, double) p,
    void Function(Path, MuscleProgressData?, {double alpha}) draw,
    Path Function(List<Offset>) curve,
    Path Function(List<Offset>) path,
  ) {
    draw(
      curve([
        p(28, 48),
        p(38, 38),
        p(52, 39),
        p(62, 54),
        p(56, 75),
        p(42, 82),
        p(31, 69),
        p(25, 61),
        p(24, 54),
        p(28, 48),
      ]),
      muscles.shoulders,
    );
    draw(
      curve([
        p(96, 48),
        p(86, 38),
        p(72, 39),
        p(62, 54),
        p(68, 75),
        p(82, 82),
        p(93, 69),
        p(99, 61),
        p(100, 54),
        p(96, 48),
      ]),
      muscles.shoulders,
    );
    draw(
      curve([
        p(38, 58),
        p(44, 47),
        p(56, 51),
        p(62, 61),
        p(60, 84),
        p(48, 94),
        p(37, 84),
        p(32, 74),
        p(32, 65),
        p(38, 58),
      ]),
      muscles.chest,
    );
    draw(
      curve([
        p(86, 58),
        p(80, 47),
        p(68, 51),
        p(62, 61),
        p(64, 84),
        p(76, 94),
        p(87, 84),
        p(92, 74),
        p(92, 65),
        p(86, 58),
      ]),
      muscles.chest,
    );
    draw(
      curve([
        p(46, 92),
        p(54, 88),
        p(70, 88),
        p(78, 92),
        p(82, 125),
        p(75, 154),
        p(62, 164),
        p(49, 154),
        p(42, 125),
        p(46, 92),
      ]),
      muscles.core,
    );
    draw(
      curve([
        p(36, 153),
        p(47, 145),
        p(77, 145),
        p(88, 153),
        p(82, 176),
        p(68, 183),
        p(62, 170),
        p(56, 183),
        p(42, 176),
        p(36, 153),
      ]),
      muscles.hips,
    );
    _drawArms(p, draw, curve);
    _drawLegs(p, draw, curve);
  }

  void _drawBack(
    Canvas canvas,
    Offset Function(double, double) p,
    void Function(Path, MuscleProgressData?, {double alpha}) draw,
    Path Function(List<Offset>) curve,
    Path Function(List<Offset>) path,
  ) {
    draw(
      curve([
        p(28, 48),
        p(42, 36),
        p(54, 42),
        p(62, 58),
        p(54, 82),
        p(38, 86),
        p(27, 68),
        p(23, 58),
        p(24, 52),
        p(28, 48),
      ]),
      muscles.shoulders,
    );
    draw(
      curve([
        p(96, 48),
        p(82, 36),
        p(70, 42),
        p(62, 58),
        p(70, 82),
        p(86, 86),
        p(97, 68),
        p(101, 58),
        p(100, 52),
        p(96, 48),
      ]),
      muscles.shoulders,
    );
    draw(
      curve([
        p(39, 55),
        p(52, 50),
        p(59, 67),
        p(62, 94),
        p(56, 126),
        p(43, 139),
        p(34, 110),
        p(29, 82),
        p(31, 63),
        p(39, 55),
      ]),
      muscles.chest,
    );
    draw(
      curve([
        p(85, 55),
        p(72, 50),
        p(65, 67),
        p(62, 94),
        p(68, 126),
        p(81, 139),
        p(90, 110),
        p(95, 82),
        p(93, 63),
        p(85, 55),
      ]),
      muscles.chest,
    );
    draw(
      curve([
        p(47, 114),
        p(54, 106),
        p(70, 106),
        p(77, 114),
        p(81, 143),
        p(74, 160),
        p(62, 168),
        p(50, 160),
        p(43, 143),
        p(47, 114),
      ]),
      muscles.core,
      alpha: 0.86,
    );
    draw(
      curve([
        p(36, 153),
        p(47, 145),
        p(77, 145),
        p(88, 153),
        p(83, 178),
        p(70, 184),
        p(62, 171),
        p(54, 184),
        p(41, 178),
        p(36, 153),
      ]),
      muscles.hips,
    );
    _drawArms(p, draw, curve);
    _drawLegs(p, draw, curve);
  }

  void _drawArms(
    Offset Function(double, double) p,
    void Function(Path, MuscleProgressData?, {double alpha}) draw,
    Path Function(List<Offset>) curve,
  ) {
    draw(
      curve([
        p(27, 66),
        p(15, 76),
        p(10, 101),
        p(15, 125),
        p(21, 136),
        p(29, 117),
        p(32, 86),
        p(34, 73),
        p(31, 67),
        p(27, 66),
      ]),
      muscles.leftArm,
    );
    draw(
      curve([
        p(97, 66),
        p(109, 76),
        p(114, 101),
        p(109, 125),
        p(103, 136),
        p(95, 117),
        p(92, 86),
        p(90, 73),
        p(93, 67),
        p(97, 66),
      ]),
      muscles.rightArm,
    );
    draw(
      curve([
        p(14, 126),
        p(6, 138),
        p(8, 154),
        p(18, 162),
        p(27, 154),
        p(25, 139),
        p(21, 132),
        p(14, 126),
      ]),
      muscles.leftArm,
      alpha: 0.82,
    );
    draw(
      curve([
        p(110, 126),
        p(118, 138),
        p(116, 154),
        p(106, 162),
        p(97, 154),
        p(99, 139),
        p(103, 132),
        p(110, 126),
      ]),
      muscles.rightArm,
      alpha: 0.82,
    );
  }

  void _drawLegs(
    Offset Function(double, double) p,
    void Function(Path, MuscleProgressData?, {double alpha}) draw,
    Path Function(List<Offset>) curve,
  ) {
    draw(
      curve([
        p(42, 174),
        p(55, 170),
        p(62, 185),
        p(58, 225),
        p(52, 245),
        p(39, 238),
        p(35, 207),
        p(34, 185),
        p(38, 176),
        p(42, 174),
      ]),
      muscles.leftLeg,
    );
    draw(
      curve([
        p(82, 174),
        p(69, 170),
        p(62, 185),
        p(66, 225),
        p(72, 245),
        p(85, 238),
        p(89, 207),
        p(90, 185),
        p(86, 176),
        p(82, 174),
      ]),
      muscles.rightLeg,
    );
    draw(
      curve([
        p(38, 236),
        p(48, 229),
        p(56, 241),
        p(54, 276),
        p(43, 282),
        p(35, 267),
        p(34, 247),
        p(38, 236),
      ]),
      muscles.calves,
      alpha: 0.84,
    );
    draw(
      curve([
        p(86, 236),
        p(76, 229),
        p(68, 241),
        p(70, 276),
        p(81, 282),
        p(89, 267),
        p(90, 247),
        p(86, 236),
      ]),
      muscles.calves,
      alpha: 0.84,
    );
  }

  @override
  bool shouldRepaint(covariant _MuscleFigurePainter oldDelegate) {
    return oldDelegate.muscles != muscles || oldDelegate.isBack != isBack;
  }
}

class _PriorityMuscles extends StatelessWidget {
  final List<MuscleProgressData> items;

  const _PriorityMuscles({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weak Muscle Priority',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => _PriorityRow(item: item)),
        ],
      ),
    );
  }
}

class _PriorityRow extends StatelessWidget {
  final MuscleProgressData item;

  const _PriorityRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _tierColor(item),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            'Lv ${item.level}  ${item.currentLevelExp}/${item.expToNextLevel} XP',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

Color _tierColor(MuscleProgressData item) {
  switch (item.tier.toLowerCase()) {
    case 'champion':
      return const Color(0xFF7C63FF);
    case 'diamond':
      return const Color(0xFF48A7FF);
    case 'platinum':
      return const Color(0xFFE24D5C);
    case 'gold':
      return const Color(0xFFE8C547);
    case 'silver':
      return const Color(0xFFBFC7D5);
    case 'bronze':
      return const Color(0xFFB87333);
    case 'iron':
    default:
      return const Color(0xFF6B7280);
  }
}

Color _figureColor(MuscleProgressData? item) {
  if (item == null) {
    return const Color(0xFFCDD5D7);
  }

  // Nếu chưa tập luyện (0 XP) → màu xám mặc định
  if (item.totalExp <= 0) {
    return const Color(0xFF6B7280);
  }

  // Tô màu dựa trên tier
  return _tierColor(item);
}

class MuscleProgressData {
  final String id;
  final String name;
  final String category;
  final int level;
  final int totalExp;
  final int currentLevelExp;
  final int expToNextLevel;
  final double progress;
  final String tier;
  final bool isLagging;

  const MuscleProgressData({
    required this.id,
    required this.name,
    required this.category,
    required this.level,
    required this.totalExp,
    required this.currentLevelExp,
    required this.expToNextLevel,
    required this.progress,
    required this.tier,
    required this.isLagging,
  });
}
