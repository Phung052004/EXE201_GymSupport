import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:gym_support/core/constants/app_colors.dart';
import 'package:gym_support/core/constants/app_theme.dart';
import 'package:gym_support/core/services/backend_api.dart';
import 'package:gym_support/models/workout_models.dart';
import 'workout_plan_detail_screen.dart';

class WorkoutPlansScreen extends StatefulWidget {
  const WorkoutPlansScreen({super.key});

  @override
  State<WorkoutPlansScreen> createState() => _WorkoutPlansScreenState();
}

class _WorkoutPlansScreenState extends State<WorkoutPlansScreen> {
  List<WorkoutPlan> _plans = [];
  bool _loading = true;
  String? _error;
  final Set<String> _activating = {};

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() { _loading = true; _error = null; });
    try {
      final userId = await BackendApi.currentUserId();
      if (userId == null || userId.isEmpty) throw Exception('Chưa đăng nhập');
      final data = await BackendApi.getWorkoutPlansByUser(userId);
      if (!mounted) return;
      setState(() {
        _plans = (data as List).map((e) => WorkoutPlan.fromJson(e as Map<String, dynamic>)).toList();
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _activate(String planId) async {
    setState(() => _activating.add(planId));
    try {
      await BackendApi.activateWorkoutPlan(planId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã kích hoạt lịch tập'),
          backgroundColor: AppColors.surface3,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      await _loadPlans();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _activating.remove(planId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
              child: Row(
                children: [
                  if (Navigator.canPop(context))
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppColors.textPrimary, size: 20),
                    )
                  else
                    const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Lịch tập của tôi',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (!_loading)
                          Text(
                            '${_plans.length} kế hoạch',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _loadPlans,
                    icon: const Icon(PhosphorIconsBold.arrowClockwise, color: AppColors.textSecondary, size: 22),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return _buildSkeleton();
    if (_error != null) {
      return Center(child: AppErrorState(message: _error, onRetry: _loadPlans));
    }
    if (_plans.isEmpty) {
      return Center(
        child: AppEmptyState(
          icon: PhosphorIconsBold.notepad,
          title: 'Chưa có lịch tập',
          message: 'Tạo lịch tập đầu tiên của bạn\ntrong tab Routine hoặc để AI tạo',
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: _loadPlans,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        itemCount: _plans.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _PlanCard(
          plan: _plans[i],
          isActivating: _activating.contains(_plans[i].id),
          onActivate: () => _activate(_plans[i].id),
          onDetail: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WorkoutPlanDetailScreen(planId: _plans[i].id),
              ),
            );
            _loadPlans();
          },
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => SkeletonBox(
        width: double.infinity,
        height: 160,
        radius: AppTheme.radiusLg,
      ),
    );
  }
}

// ── Plan Card ────────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final WorkoutPlan plan;
  final bool isActivating;
  final VoidCallback onActivate;
  final VoidCallback onDetail;

  const _PlanCard({
    required this.plan,
    required this.isActivating,
    required this.onActivate,
    required this.onDetail,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = plan.isActive;

    return GestureDetector(
      onTap: onDetail,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.outline,
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: isActive ? AppTheme.heroGradient : null,
                color: isActive ? null : AppColors.surface2,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusLg),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isActive) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                            ),
                            child: const Text(
                              '● ĐANG HOẠT ĐỘNG',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                        Text(
                          plan.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : AppColors.surface3,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      PhosphorIconsBold.notepad,
                      color: isActive ? AppColors.primary : AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            // Info pills
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (plan.goal.isNotEmpty)
                    _InfoPill(PhosphorIconsBold.flag, plan.goal, AppColors.blue),
                  _InfoPill(
                    PhosphorIconsBold.calendarCheck,
                    '${plan.daysPerWeek} buổi/tuần',
                    AppColors.orange,
                  ),
                ],
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onDetail,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.outlineStrong),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      child: const Text('Chi tiết'),
                    ),
                  ),
                  if (!isActive) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: isActivating ? null : AppTheme.cyanGradient,
                          color: isActivating ? AppColors.surface2 : null,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        ),
                        child: ElevatedButton(
                          onPressed: isActivating ? null : onActivate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            disabledBackgroundColor: Colors.transparent,
                            foregroundColor: AppColors.textDark,
                            disabledForegroundColor: AppColors.textSecondary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                          ),
                          child: isActivating
                              ? const SizedBox(
                                  width: 16, height: 16,
                                  child: CircularProgressIndicator(
                                    color: AppColors.textSecondary, strokeWidth: 2,
                                  ),
                                )
                              : const Text('Kích hoạt'),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoPill(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
