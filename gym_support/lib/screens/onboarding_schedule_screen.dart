import 'package:flutter/material.dart';

import 'package:gym_support/core/constants/app_colors.dart';
import 'package:gym_support/core/services/backend_api.dart';
import 'package:gym_support/core/services/session_store.dart';
import 'package:gym_support/models/training_schedule.dart';
import 'package:gym_support/widgets/primary_button.dart';
import 'package:gym_support/widgets/secondary_button.dart';
import 'package:gym_support/features/main/screens/main_navigation_screen.dart';
import 'package:gym_support/widgets/app_logo.dart';
import 'package:gym_support/widgets/onboarding_title.dart';
import 'package:gym_support/widgets/schedule_option_card.dart';
import 'package:gym_support/widgets/step_indicator.dart';

class OnboardingScheduleScreen extends StatefulWidget {
  final String email;
  final String name;
  final String gender;
  final String age;
  final String weight;
  final String height;
  final String bmi;
  final String goal;

  const OnboardingScheduleScreen({
    super.key,
    required this.email,
    required this.name,
    required this.gender,
    required this.age,
    required this.weight,
    required this.height,
    required this.bmi,
    required this.goal,
  });

  @override
  State<OnboardingScheduleScreen> createState() =>
      _OnboardingScheduleScreenState();
}

class _OnboardingScheduleScreenState extends State<OnboardingScheduleScreen> {
  String selectedSchedule = '4 ngày/tuần';
  bool _isSaving = false;

  final List<TrainingSchedule> schedules = const [
    TrainingSchedule(
      title: '3 ngày/tuần',
      subtitle: 'Beginner',
      description: 'Phù hợp người mới bắt đầu, dễ duy trì.',
      icon: Icons.calendar_month,
      color: Color(0xFF12E67F),
    ),
    TrainingSchedule(
      title: '4 ngày/tuần',
      subtitle: 'Balanced',
      description: 'Cân bằng giữa tập luyện và phục hồi.',
      icon: Icons.event_available,
      color: Color(0xFF248DFF),
    ),
    TrainingSchedule(
      title: '5 ngày/tuần',
      subtitle: 'Intermediate',
      description: 'Tốt cho người đã quen tập đều đặn.',
      icon: Icons.fitness_center,
      color: Color(0xFFFF7A30),
    ),
    TrainingSchedule(
      title: '6 ngày/tuần',
      subtitle: 'Advanced',
      description: 'Cường độ cao, cần ngủ và ăn uống tốt.',
      icon: Icons.flash_on,
      color: Color(0xFFC44DFF),
    ),
    TrainingSchedule(
      title: '7 ngày/tuần',
      subtitle: 'Athlete',
      description: 'Chỉ nên dùng nếu có ngày tập nhẹ/phục hồi.',
      icon: Icons.workspace_premium,
      color: Color(0xFFFF3D8B),
    ),
  ];

  Future<void> finishOnboarding() async {
    if (_isSaving) return;

    debugPrint('===== USER PROFILE =====');
    debugPrint('Tên: ${widget.name}');
    debugPrint('Giới tính: ${widget.gender}');
    debugPrint('Tuổi: ${widget.age}');
    debugPrint('Cân nặng: ${widget.weight} kg');
    debugPrint('Chiều cao: ${widget.height} cm');
    debugPrint('BMI: ${widget.bmi}');
    debugPrint('Mục tiêu: ${widget.goal}');
    debugPrint('Lịch tập: $selectedSchedule');

    setState(() {
      _isSaving = true;
    });

    try {
      await BackendApi.saveOnboardingProfile(
        email: widget.email,
        name: widget.name,
        gender: widget.gender,
        age: widget.age,
        weight: widget.weight,
        height: widget.height,
        bmi: widget.bmi,
        goal: widget.goal,
        schedule: selectedSchedule,
      );
      await SessionStore.savePendingEmail(widget.email);
      await SessionStore.markProfileComplete();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể kết nối backend: $error')),
      );
      setState(() {
        _isSaving = false;
      });
      return;
    }

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => MainNavigationScreen(
          name: widget.name,
          goal: widget.goal,
          schedule: selectedSchedule,
          bmi: widget.bmi,
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedScheduleObject = schedules.firstWhere(
      (schedule) => schedule.title == selectedSchedule,
    );

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
                      const SizedBox(height: 30),

                      const AppLogo(),

                      const SizedBox(height: 22),

                      const OnboardingTitle(),

                      const SizedBox(height: 26),

                      const StepIndicator(currentStep: 4, totalSteps: 4),

                      const SizedBox(height: 30),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Choose your training schedule',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Bạn có thể thay đổi lịch tập sau trong phần Profile.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      Column(
                        children: schedules.map((schedule) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ScheduleOptionCard(
                              schedule: schedule,
                              isSelected: selectedSchedule == schedule.title,
                              onTap: () {
                                setState(() {
                                  selectedSchedule = schedule.title;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 18),

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
                              text: _isSaving ? 'Saving...' : 'Continue',
                              icon: selectedScheduleObject.icon,
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
