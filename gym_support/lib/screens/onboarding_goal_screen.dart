import 'package:flutter/material.dart';

import 'package:gym_support/core/constants/app_colors.dart';
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
      icon: Icons.fitness_center,
      color: Color(0xFF12E67F),
    ),
    FitnessGoal(
      title: 'Giảm Cân',
      subtitle: 'Lose Weight',
      icon: Icons.local_fire_department,
      color: Color(0xFFFF7A30),
    ),
    FitnessGoal(
      title: 'Tăng Sức Mạnh',
      subtitle: 'Increase Strength',
      icon: Icons.flash_on,
      color: Color(0xFF248DFF),
    ),
    FitnessGoal(
      title: 'Tăng Sức Bền',
      subtitle: 'Boost Endurance',
      icon: Icons.show_chart,
      color: Color(0xFFC44DFF),
    ),
    FitnessGoal(
      title: 'Giữ Sức Khỏe',
      subtitle: 'Stay Healthy',
      icon: Icons.favorite,
      color: Color(0xFFFF3D8B),
    ),
  ];

  void finishOnboarding() {
    debugPrint('===== USER PROFILE =====');
    debugPrint('Tên: ${widget.name}');
    debugPrint('Giới tính: ${widget.gender}');
    debugPrint('Tuổi: ${widget.age}');
    debugPrint('Cân nặng: ${widget.weight} kg');
    debugPrint('Chiều cao: ${widget.height} cm');
    debugPrint('BMI: ${widget.bmi}');
    debugPrint('Mục tiêu: ${selectedGoals.join(', ')}');

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
    final FitnessGoal? selectedGoalObject = selectedGoals.isNotEmpty
        ? goals.firstWhere((goal) => goal.title == selectedGoals.first)
        : null;

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
                    children: [
                      const SizedBox(height: 36),
                      const AppLogo(),
                      const SizedBox(height: 24),
                      const OnboardingTitle(),
                      const SizedBox(height: 28),
                      const StepIndicator(currentStep: 3, totalSteps: 3),
                      const SizedBox(height: 32),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "What's your goal?",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

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
                            width: 82,
                            child: SecondaryButton(
                              text: 'Back',
                              onTap: () {
                                Navigator.pop(context);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: PrimaryButton(
                              text: 'Start My Journey',
                              icon: selectedGoalObject?.icon,
                              onTap: finishOnboarding,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),
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
