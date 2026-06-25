import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:gym_support/core/constants/app_colors.dart';
import 'package:gym_support/core/constants/app_theme.dart';
import '../models/fitness_goal.dart';
import '../widgets/widgets.dart';
import 'onboarding_schedule_screen.dart';

class OnboardingGoalScreen extends StatefulWidget {
  final String email;
  final String name;
  final String gender;
  final String age;
  final String weight;
  final String height;
  final String bmi;

  const OnboardingGoalScreen({
    super.key,
    required this.email,
    required this.name,
    required this.gender,
    required this.age,
    required this.weight,
    required this.height,
    required this.bmi,
  });

  @override
  State<OnboardingGoalScreen> createState() => _OnboardingGoalScreenState();
}

class _OnboardingGoalScreenState extends State<OnboardingGoalScreen> {
  final List<String> selectedGoals = [];

  final List<FitnessGoal> goals = const [
    FitnessGoal(
      title: 'Tăng Cơ Bắp',
      subtitle: 'Build Muscle',
      icon: PhosphorIconsBold.barbell,
      color: AppColors.primary,
    ),
    FitnessGoal(
      title: 'Giảm Cân',
      subtitle: 'Lose Weight',
      icon: PhosphorIconsBold.fire,
      color: Color(0xFFFFB545),
    ),
    FitnessGoal(
      title: 'Tăng Sức Mạnh',
      subtitle: 'Increase Strength',
      icon: PhosphorIconsBold.lightning,
      color: Color(0xFF8B5CF6),
    ),
    FitnessGoal(
      title: 'Tăng Sức Bền',
      subtitle: 'Boost Endurance',
      icon: PhosphorIconsBold.chartLine,
      color: Color(0xFF06B6D4),
    ),
    FitnessGoal(
      title: 'Giữ Sức Khỏe',
      subtitle: 'Stay Healthy',
      icon: PhosphorIconsBold.heart,
      color: Color(0xFFFF5C8A),
    ),
  ];

  void finishOnboarding() {
    if (selectedGoals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất 1 mục tiêu')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OnboardingScheduleScreen(
          email: widget.email,
          name: widget.name,
          gender: widget.gender,
          age: widget.age,
          weight: widget.weight,
          height: widget.height,
          bmi: widget.bmi,
          goal: selectedGoals.join(', '),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),
                      const Text(
                        'Mục tiêu của bạn?',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Chọn những gì bạn muốn đạt được',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      StepIndicator(currentStep: 3, totalSteps: 3),
                      const SizedBox(height: 28),

                      if (selectedGoals.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: AppTheme.cyanGradient,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(PhosphorIconsBold.checkCircle,
                                  color: AppColors.textDark, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                '${selectedGoals.length} mục tiêu đã chọn',
                                style: const TextStyle(
                                  color: AppColors.textDark,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      Column(
                        children: goals.map((goal) {
                          final isSelected = selectedGoals.contains(goal.title);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GoalOptionCard(
                              goal: goal,
                              isSelected: isSelected,
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    selectedGoals.remove(goal.title);
                                  } else {
                                    selectedGoals.add(goal.title);
                                  }
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 20),
                      Row(
                        children: [
                          SizedBox(
                            width: 100,
                            child: SecondaryButton(
                              text: 'Quay lại',
                              onTap: () => Navigator.pop(context),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: PrimaryButton(
                              text: 'Tiếp tục',
                              onTap: finishOnboarding,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
