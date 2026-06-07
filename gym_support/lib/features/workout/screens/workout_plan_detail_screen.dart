import 'package:flutter/material.dart';
import 'package:gym_support/core/constants/app_colors.dart';
import 'package:gym_support/core/services/backend_api.dart';
import 'package:gym_support/models/workout_models.dart';

class WorkoutPlanDetailScreen extends StatefulWidget {
  final String planId;

  const WorkoutPlanDetailScreen({super.key, required this.planId});

  @override
  State<WorkoutPlanDetailScreen> createState() => _WorkoutPlanDetailScreenState();
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã kích hoạt lịch tập!')),
        );
        _loadPlan();
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString();
        if (msg.contains('Exception: ')) msg = msg.split('Exception: ').last;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $msg')),
        );
        _loadPlan();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_plan?.name ?? 'Plan Detail', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_error != null || _plan == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error ?? 'Lỗi không xác định', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadPlan, child: const Text('Thử lại')),
          ],
        ),
      );
    }

    final plan = _plan!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Goal', plan.goal),
          _buildInfoRow('Level', plan.level),
          _buildInfoRow('Days per week', plan.daysPerWeek.toString()),
          _buildInfoRow('Status', plan.isActive ? 'Active' : 'Inactive', 
              color: plan.isActive ? AppColors.primary : Colors.white70),
          
          if (plan.description.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('Description', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(plan.description, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ],

          const SizedBox(height: 30),
          const Text('Workout Days:', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          
          ...plan.workoutDays.map((day) => _buildDayCard(day)).toList(),

          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: plan.isActive ? null : _applyPlan,
              style: ElevatedButton.styleFrom(
                backgroundColor: plan.isActive ? Colors.grey : AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(plan.isActive ? 'Currently Active' : 'Apply Plan'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(color: Colors.white70, fontSize: 15)),
          Text(value, style: TextStyle(color: color ?? Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDayCard(WorkoutDay day) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${day.dayName}: ${day.focus}',
            style: const TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...day.exercises.map((ex) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                const Icon(Icons.circle, size: 6, color: Colors.white38),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${ex.exerciseName}: ${ex.sets} sets x ${ex.reps}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }
}
