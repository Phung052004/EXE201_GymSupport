import 'package:flutter/material.dart';
import 'package:gym_support/core/constants/app_colors.dart';

class WorkoutSummaryScreen extends StatelessWidget {
  final Map<String, dynamic> summary;

  const WorkoutSummaryScreen({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final int totalSets = summary['totalSets'] ?? 0;
    final int totalExp = summary['totalExpGained'] ?? 0;
    final List exercises = summary['exercises'] ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.check_circle, color: Color(0xFF12E67F), size: 100),
              const SizedBox(height: 24),
              const Text(
                'Workout Completed!',
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                'Great job pushing through your limits!',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
              ),
              
              const SizedBox(height: 40),
              
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow('Plan', summary['planName']),
                    _buildSummaryRow('Day', summary['dayName']),
                    _buildSummaryRow('Duration', summary['duration']),
                    const Divider(color: Colors.white10, height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat('SETS', totalSets.toString()),
                        _buildStat('EXP', '+$totalExp'),
                        _buildStat('STATUS', 'COMPLETED', color: const Color(0xFF12E67F)),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Completed Exercises:', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              
              ...exercises.map((ex) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(ex['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text('${ex['sets']} sets', style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              )).toList(),
              
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                  child: const Text('Back Home'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // Navigate to history
                },
                child: const Text('View History', style: TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 14)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color ?? Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
      ],
    );
  }
}
