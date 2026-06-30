import 'package:flutter/material.dart';
import 'package:gym_support/core/constants/app_colors.dart';
import 'package:gym_support/core/constants/app_theme.dart';
import 'package:gym_support/core/services/backend_api.dart';
import 'package:gym_support/models/workout_models.dart';
import 'package:gym_support/models/exercise.dart';
import 'exercise_selection_screen.dart';

class WorkoutPlanDetailScreen extends StatefulWidget {
  final String planId;
  const WorkoutPlanDetailScreen({super.key, required this.planId});

  @override
  State<WorkoutPlanDetailScreen> createState() => _WorkoutPlanDetailScreenState();
}

class _WorkoutPlanDetailScreenState extends State<WorkoutPlanDetailScreen> {
  WorkoutPlan? _plan;
  bool _loading = true;
  String? _error;
  bool _activating = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await BackendApi.getWorkoutPlanById(widget.planId);
      if (!mounted) return;
      setState(() => _plan = WorkoutPlan.fromJson(data));
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _activate() async {
    setState(() => _activating = true);
    try {
      await BackendApi.activateWorkoutPlan(widget.planId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã kích hoạt lịch tập')),
      );
      await _loadPlan();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _activating = false);
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Xóa lịch tập?', style: AppTheme.headlineSmall),
        content: const Text('Hành động này không thể hoàn tác.', style: AppTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      await BackendApi.deleteWorkoutPlan(widget.planId);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _deleting = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  Future<void> _showEditDialog() async {
    if (_plan == null) return;
    final nameCtrl = TextEditingController(text: _plan!.name);
    final goalCtrl = TextEditingController(text: _plan!.goal ?? '');
    final daysCtrl = TextEditingController(text: _plan!.daysPerWeek?.toString() ?? '');
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Chỉnh sửa', style: AppTheme.headlineSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: AppTheme.inputDecoration(hint: 'Tên lịch tập'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: goalCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: AppTheme.inputDecoration(hint: 'Mục tiêu'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: daysCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              keyboardType: TextInputType.number,
              decoration: AppTheme.inputDecoration(hint: 'Số buổi/tuần'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textDark,
            ),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await BackendApi.updateWorkoutPlan(widget.planId, {
                  'name': nameCtrl.text.trim(),
                  'goal': goalCtrl.text.trim(),
                  'daysPerWeek': int.tryParse(daysCtrl.text) ?? _plan!.daysPerWeek,
                });
                await _loadPlan();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                }
              } finally {
                nameCtrl.dispose();
                goalCtrl.dispose();
                daysCtrl.dispose();
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? _buildSkeleton()
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildSkeleton() {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textPrimary),
                ),
                const Expanded(
                  child: SkeletonBox(width: 180, height: 22, radius: AppTheme.radiusSm),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: SkeletonBox(width: double.infinity, height: 120, radius: AppTheme.radiusLg),
          ),
          const SizedBox(height: 16),
          ...List.generate(
            3,
            (_) => const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: SkeletonBox(width: double.infinity, height: 80, radius: AppTheme.radiusMd),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: BackButton(color: AppColors.textPrimary),
            ),
          ),
          Expanded(child: Center(child: AppErrorState(message: _error, onRetry: _loadPlan))),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final plan = _plan!;
    return CustomScrollView(
      slivers: [
        // ── App Bar ──────────────────────────────────────────────────────────
        SliverAppBar(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          pinned: true,
          elevation: 0,
          title: Text(plan.name, style: AppTheme.titleLarge,
              overflow: TextOverflow.ellipsis),
          actions: [
            IconButton(
              onPressed: _showEditDialog,
              icon: const Icon(Icons.edit_rounded, size: 20),
              color: AppColors.textSecondary,
            ),
            IconButton(
              onPressed: _deleting ? null : _confirmDelete,
              icon: _deleting
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          color: AppColors.danger, strokeWidth: 2))
                  : const Icon(Icons.delete_outline_rounded, size: 20),
              color: AppColors.danger,
            ),
          ],
        ),

        // ── Plan Header card ─────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            padding: const EdgeInsets.all(20),
            decoration: plan.isActive
                ? AppTheme.glowCardDecoration(glowColor: AppColors.primary)
                : AppTheme.cardDecoration(radius: AppTheme.radiusLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (plan.isActive)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Text(
                      'ĐANG HOẠT ĐỘNG',
                      style: TextStyle(
                        color: AppColors.textDark, fontSize: 10,
                        fontWeight: FontWeight.w900, letterSpacing: 0.5,
                      ),
                    ),
                  ),
                Text(plan.name, style: AppTheme.headlineMedium),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (plan.goal.isNotEmpty)
                      _Pill(Icons.flag_rounded, plan.goal, AppColors.blue),
                    _Pill(Icons.calendar_today_rounded,
                        '${plan.daysPerWeek} buổi/tuần', AppColors.orange),
                    _Pill(Icons.schedule_rounded, '8 tuần', AppColors.violet),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── Days ─────────────────────────────────────────────────────────────
        if (plan.workoutDays.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
              child: SectionHeader(title: 'Lịch tập'),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _DayCard(
                day: plan.workoutDays[i],
                index: i,
                planId: plan.id,
                onChanged: _loadPlan,
              ),
              childCount: plan.workoutDays.length,
            ),
          ),
        ],

        // ── Nutrition Tips ───────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.violet.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppColors.violet.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.violet.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.restaurant_rounded,
                          color: AppColors.violet, size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Text('Mẹo dinh dưỡng', style: AppTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '• Ăn đủ protein (1.6–2.2g / kg cân nặng)\n'
                  '• Uống 2–3 lít nước mỗi ngày\n'
                  '• Ưu tiên thực phẩm nguyên hạt và rau củ\n'
                  '• Bổ sung carb trước tập để có năng lượng',
                  style: AppTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),

        // ── Activate Button ──────────────────────────────────────────────────
        if (!plan.isActive)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
              child: ElevatedButton(
                onPressed: _activating ? null : _activate,
                style: AppTheme.primaryButtonStyle(),
                child: _activating
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                            color: AppColors.textDark, strokeWidth: 2.5))
                    : const Text('Kích hoạt lịch tập này'),
              ),
            ),
          )
        else
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

class _DayCard extends StatefulWidget {
  final WorkoutDay day;
  final int index;
  final String planId;
  final Future<void> Function() onChanged;
  const _DayCard({
    required this.day,
    required this.index,
    required this.planId,
    required this.onChanged,
  });

  @override
  State<_DayCard> createState() => _DayCardState();
}

class _DayCardState extends State<_DayCard> {
  bool _expanded = false;
  bool _busy = false;

  Future<void> _editExercise(WorkoutExercise ex) async {
    final setsCtrl = TextEditingController(text: ex.sets.toString());
    final repsCtrl = TextEditingController(text: ex.reps);
    final notesCtrl = TextEditingController(text: ex.note);
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(ex.exerciseName, style: AppTheme.headlineSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: setsCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              keyboardType: TextInputType.number,
              decoration: AppTheme.inputDecoration(hint: 'Số set'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: repsCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: AppTheme.inputDecoration(hint: 'Số rep (vd: 10 hoặc 8-12)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: AppTheme.inputDecoration(hint: 'Ghi chú'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textDark,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    final sets = int.tryParse(setsCtrl.text.trim()) ?? ex.sets;
    final reps = repsCtrl.text.trim();
    final notes = notesCtrl.text.trim();
    setsCtrl.dispose();
    repsCtrl.dispose();
    notesCtrl.dispose();
    if (saved != true) return;
    setState(() => _busy = true);
    try {
      await BackendApi.updateExerciseInPlanSession(
        planId: widget.planId,
        sessionId: widget.day.id,
        exerciseId: ex.exerciseId,
        sets: sets,
        reps: reps.isEmpty ? ex.reps : reps,
        notes: notes,
      );
      await widget.onChanged();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteExercise(WorkoutExercise ex) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Xóa bài tập?', style: AppTheme.headlineSmall),
        content: Text('Xóa "${ex.exerciseName}" khỏi buổi tập này?',
            style: AppTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await BackendApi.deleteExerciseFromPlanSession(
        planId: widget.planId,
        sessionId: widget.day.id,
        exerciseId: ex.exerciseId,
      );
      await widget.onChanged();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addExercise() async {
    final picked = await Navigator.push<Exercise>(
      context,
      MaterialPageRoute(builder: (_) => const ExerciseSelectionScreen()),
    );
    if (picked == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await BackendApi.addExerciseToPlanSession(
        planId: widget.planId,
        sessionId: widget.day.id,
        exerciseId: picked.id,
        exerciseName: picked.name,
        sets: picked.defaultSets,
        reps: picked.defaultReps,
      );
      await widget.onChanged();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final day = widget.day;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      decoration: AppTheme.cardDecoration(radius: AppTheme.radiusLg),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '${widget.index + 1}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(day.dayName, style: AppTheme.titleMedium),
                        if (day.focus.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(day.focus, style: AppTheme.caption),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      '${day.exercises.length} bài',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),

          // Expanded exercise list
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _expanded
                ? Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: AppColors.outline)),
                    ),
                    child: Column(
                      children: [
                        ...day.exercises.asMap().entries.map((entry) {
                          final i = entry.key;
                          final ex = entry.value;
                          return Container(
                            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                            decoration: const BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(color: AppColors.outline)),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  child: Text(
                                    '${i + 1}',
                                    style: const TextStyle(
                                      color: AppColors.textTertiary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ex.exerciseName,
                                        style: AppTheme.bodyMedium.copyWith(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w500),
                                      ),
                                      Text(
                                        '${ex.sets}×${ex.reps}',
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  onPressed: _busy ? null : () => _editExercise(ex),
                                  icon: const Icon(Icons.edit_rounded, size: 18),
                                  color: AppColors.textSecondary,
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  onPressed: _busy ? null : () => _deleteExercise(ex),
                                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                  color: AppColors.danger,
                                ),
                              ],
                            ),
                          );
                        }),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _busy ? null : _addExercise,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: BorderSide(
                                    color: AppColors.primary.withValues(alpha: 0.5)),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radiusMd),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              icon: _busy
                                  ? const SizedBox(
                                      width: 16, height: 16,
                                      child: CircularProgressIndicator(
                                          color: AppColors.primary, strokeWidth: 2))
                                  : const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Thêm bài tập'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Pill(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
