import 'package:flutter/material.dart';
import 'package:gym_support/core/constants/app_colors.dart';
import 'package:gym_support/core/services/backend_api.dart';
import 'package:gym_support/models/workout_models.dart';

class WorkoutPlanDetailScreen extends StatefulWidget {
  final String planId;

  const WorkoutPlanDetailScreen({super.key, required this.planId});

  @override
  State<WorkoutPlanDetailScreen> createState() =>
      _WorkoutPlanDetailScreenState();
}

class _WorkoutPlanDetailScreenState extends State<WorkoutPlanDetailScreen> {
  WorkoutPlan? _plan;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await BackendApi.getWorkoutPlanById(widget.planId);
      setState(() {
        _plan = WorkoutPlan.fromJson(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Không thể tải chi tiết workout plan.';
        _isLoading = false;
      });
    }
  }

  Future<void> _applyPlan() async {
    if (_plan == null) return;
    try {
      await BackendApi.activateWorkoutPlan(_plan!.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã kích hoạt lịch tập!')));
        _loadPlan();
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString();
        if (msg.contains('Exception: ')) msg = msg.split('Exception: ').last;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $msg')));
        _loadPlan();
      }
    }
  }

  Future<void> _editPlan() async {
    final plan = _plan;
    if (plan == null || _isLoading) return;

    final nameController = TextEditingController(text: plan.name);
    final goalController = TextEditingController(text: plan.goal);
    final descriptionController = TextEditingController(text: plan.description);
    final daysController = TextEditingController(
      text: plan.daysPerWeek.toString(),
    );

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Chỉnh sửa lịch tập'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Tên lịch tập'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: goalController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Mục tiêu'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: daysController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Số buổi mỗi tuần',
                  helperText: 'Từ 1 đến 7 buổi',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                minLines: 3,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Mô tả'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              final days = int.tryParse(daysController.text.trim());
              if (nameController.text.trim().isEmpty ||
                  goalController.text.trim().isEmpty ||
                  days == null ||
                  days < 1 ||
                  days > 7) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Kiểm tra lại tên, mục tiêu và số buổi.'),
                  ),
                );
                return;
              }
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (shouldSave != true || !mounted) {
      nameController.dispose();
      goalController.dispose();
      descriptionController.dispose();
      daysController.dispose();
      return;
    }

    final days = int.parse(daysController.text.trim());
    setState(() => _isLoading = true);
    try {
      await BackendApi.updateWorkoutPlan(
        plan.id,
        plan.toJson(
          name: nameController.text.trim(),
          goal: goalController.text.trim(),
          description: descriptionController.text.trim(),
          daysPerWeek: days,
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã cập nhật lịch tập.')));
        await _loadPlan();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể cập nhật: $error')));
        setState(() => _isLoading = false);
      }
    } finally {
      nameController.dispose();
      goalController.dispose();
      descriptionController.dispose();
      daysController.dispose();
    }
  }

  Future<void> _deletePlan() async {
    final plan = _plan;
    if (plan == null || _isLoading) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.delete_forever_rounded, color: Colors.red),
        title: const Text('Xóa lịch tập?'),
        content: Text(
          'Lịch "${plan.name}" và tất cả buổi tập bên trong sẽ bị xóa. '
          'Thao tác này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);
    try {
      await BackendApi.deleteWorkoutPlan(plan.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã xóa lịch tập.')));
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể xóa: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Workout',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Chỉnh sửa',
            onPressed: _plan == null || _isLoading ? null : _editPlan,
            icon: const Icon(
              Icons.edit_outlined,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
          IconButton(
            tooltip: 'Xóa lịch tập',
            onPressed: _plan == null || _isLoading ? null : _deletePlan,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.red,
              size: 21,
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2,
        ),
      );
    }

    if (_error != null || _plan == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error ?? 'Lỗi không xác định',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadPlan, child: const Text('Thử lại')),
          ],
        ),
      );
    }

    final plan = _plan!;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPlanOverview(plan),
          const SizedBox(height: 24),
          _buildNutritionCard(),
          const SizedBox(height: 32),
          const Text(
            'WORKOUT DAYS',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          ...plan.workoutDays.map((day) => _buildDayCard(day)).toList(),
          const SizedBox(height: 32),
          if (!plan.isActive)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _applyPlan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textDark,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: AppColors.textDark,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'APPLY THIS PLAN',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
              ),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPlanOverview(WorkoutPlan plan) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  plan.name.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      plan.level.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (plan.isActive) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'ACTIVE',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildInfoBadge(Icons.calendar_today_rounded, '8 WEEKS'),
              const SizedBox(width: 12),
              _buildInfoBadge(
                Icons.repeat_rounded,
                '${plan.daysPerWeek} DAYS/WK',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.restaurant_rounded,
                size: 18,
                color: AppColors.accent,
              ),
              const SizedBox(width: 10),
              const Text(
                'Nutrition Tips',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTipRow('Consume 1.6-2.2g protein per kg bodyweight'),
          _buildTipRow('Stay hydrated with 2.5-3L water daily'),
          _buildTipRow('Focus on whole, unprocessed foods'),
        ],
      ),
    );
  }

  Widget _buildTipRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(WorkoutDay day) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${day.dayName}: ${day.focus}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.accent,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            day.targetMuscleGroups.join(', '),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildSmallBadge(
                Icons.fitness_center_rounded,
                '${day.exercises.length} Exercises',
              ),
              const SizedBox(width: 12),
              _buildSmallBadge(Icons.timer_outlined, '65 min'),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: day.exercises.length > 5 ? 5 : day.exercises.length,
              itemBuilder: (context, i) {
                return Container(
                  width: 60,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(12),
                    image: const DecorationImage(
                      image: NetworkImage(
                        'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=200&q=80',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
          if (day.dayName.toLowerCase().contains('monday')) ...[
            const SizedBox(height: 16),
            const Divider(color: AppColors.outline),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.accent,
                  size: 14,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Completed this week',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSmallBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: AppColors.accent),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
