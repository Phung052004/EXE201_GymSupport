import 'package:flutter/material.dart';
import 'package:gym_support/core/constants/app_colors.dart';
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
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await BackendApi.getWorkoutPlansByUser();
      setState(() {
        _plans = data.map((e) => WorkoutPlan.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Không thể tải danh sách workout plan.';
        _isLoading = false;
      });
    }
  }

  Future<void> _applyPlan(String planId) async {
    setState(() => _isLoading = true);
    try {
      await BackendApi.activateWorkoutPlan(planId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã kích hoạt lịch tập!')),
        );
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString();
        if (msg.contains('Exception: ')) msg = msg.split('Exception: ').last;
        // If it's a 405 or other error but it actually worked (user reported this),
        // we show a less scary message or just proceed to reload.
        debugPrint('Apply plan error (may have still worked): $e');
      }
    } finally {
      // Always reload to get the latest status from server
      await Future.delayed(const Duration(milliseconds: 500));
      _loadPlans();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Workout Plans', style: TextStyle(fontWeight: FontWeight.bold)),
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

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadPlans, child: const Text('Thử lại')),
          ],
        ),
      );
    }

    if (_plans.isEmpty) {
      return const Center(
        child: Text('Bạn chưa có workout plan nào.', style: TextStyle(color: Colors.white70)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _plans.length,
      itemBuilder: (context, index) {
        final plan = _plans[index];
        return _buildPlanCard(plan);
      },
    );
  }

  Widget _buildPlanCard(WorkoutPlan plan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: plan.isActive ? AppColors.primary : Colors.white.withOpacity(0.05),
          width: plan.isActive ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  plan.name,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              if (plan.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Active',
                    style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Goal: ${plan.goal}', style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Text('Level: ${plan.level}', style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Text('Days: ${plan.daysPerWeek} days/week', style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => WorkoutPlanDetailScreen(planId: plan.id)),
                    );
                  },
                  child: const Text('View Detail'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: plan.isActive ? null : () => _applyPlan(plan.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: plan.isActive ? Colors.grey : AppColors.primary,
                  ),
                  child: Text(plan.isActive ? 'Currently Active' : 'Apply Plan'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
