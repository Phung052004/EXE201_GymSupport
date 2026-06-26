import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/backend_api.dart';
import '../widgets/muscle_progress_card.dart';
import '../widgets/muscle_body_map_display.dart';

class MuscleDetailScreen extends StatefulWidget {
  final List<MuscleProgressData>? items;

  const MuscleDetailScreen({super.key, this.items});

  @override
  State<MuscleDetailScreen> createState() => _MuscleDetailScreenState();
}

class _MuscleDetailScreenState extends State<MuscleDetailScreen> {
  List<MuscleProgressData> _muscles = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMuscleProgress();
  }

  Future<void> _loadMuscleProgress() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final data = await BackendApi.getUserMuscleProgress();

      if (!mounted) return;

      final muscles = data
          .map((item) => MuscleProgressData(
                id: item['id'] ?? '',
                name: item['name'] ?? '',
                category: item['category'] ?? '',
                level: (item['level'] as num?)?.toInt() ?? 0,
                totalExp: (item['totalExp'] as num?)?.toInt() ?? 0,
                currentLevelExp: (item['currentLevelExp'] as num?)?.toInt() ?? 0,
                expToNextLevel:
                    (item['expToNextLevel'] as num?)?.toInt() ?? 0,
                progress: (item['progress'] as num?)?.toDouble() ?? 0.0,
                tier: item['tier'] ?? '',
                isLagging: (item['isLagging'] as bool?) ?? false,
              ))
          .toList();

      setState(() {
        _muscles = muscles;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(PhosphorIconsBold.caretLeft),
            color: AppColors.textPrimary,
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Tiến độ cơ bắp',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(PhosphorIconsBold.caretLeft),
            color: AppColors.textPrimary,
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Tiến độ cơ bắp',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                PhosphorIconsBold.warningCircle,
                color: AppColors.danger,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Không thể tải dữ liệu',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? 'Có lỗi xảy ra',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadMuscleProgress,
                icon: const Icon(PhosphorIconsBold.arrowClockwise),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(PhosphorIconsBold.caretLeft),
          color: AppColors.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tiến độ cơ bắp',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              _StatsOverview(muscles: _muscles),
              const SizedBox(height: 20),
              MuscleBodyMapDisplay(
                items: _muscles,
                isLoading: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

}

class _StatsOverview extends StatelessWidget {
  final List<MuscleProgressData> muscles;

  const _StatsOverview({required this.muscles});

  @override
  Widget build(BuildContext context) {
    if (muscles.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalExp = muscles.fold<int>(0, (sum, m) => sum + m.totalExp);
    final avgLevel = muscles.isEmpty
        ? 0
        : (muscles.fold<int>(0, (sum, m) => sum + m.level) / muscles.length)
            .round();
    final laggingCount =
        muscles.where((m) => m.isLagging).length;
    final maxLevel = muscles.isNotEmpty
        ? muscles.map((m) => m.level).reduce((a, b) => a > b ? a : b)
        : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _StatCard(
            icon: PhosphorIconsBold.lightning,
            label: 'Tổng XP',
            value: '$totalExp',
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          _StatCard(
            icon: PhosphorIconsBold.star,
            label: 'Cấp trung bình',
            value: 'Lv.$avgLevel',
            color: const Color(0xFFFFCC00),
          ),
          const SizedBox(width: 12),
          _StatCard(
            icon: PhosphorIconsBold.warning,
            label: 'Yếu',
            value: '$laggingCount',
            color: AppColors.danger,
          ),
          const SizedBox(width: 12),
          _StatCard(
            icon: PhosphorIconsBold.crown,
            label: 'Cao nhất',
            value: 'Lv.$maxLevel',
            color: const Color(0xFFCD7F32),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 6,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
