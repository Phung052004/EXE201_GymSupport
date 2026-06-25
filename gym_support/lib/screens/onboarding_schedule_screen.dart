import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:gym_support/core/constants/app_colors.dart';
import 'package:gym_support/core/services/backend_api.dart';
import 'package:gym_support/core/services/session_store.dart';
import 'package:gym_support/models/training_schedule.dart';
import 'package:gym_support/widgets/primary_button.dart';
import 'package:gym_support/widgets/secondary_button.dart';
import 'package:gym_support/features/main/screens/main_navigation_screen.dart';
import 'package:gym_support/widgets/schedule_option_card.dart';

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
      icon: PhosphorIconsBold.calendarBlank,
      color: AppColors.primary,
    ),
    TrainingSchedule(
      title: '4 ngày/tuần',
      subtitle: 'Balanced',
      description: 'Cân bằng giữa tập luyện và phục hồi.',
      icon: PhosphorIconsBold.calendarCheck,
      color: Color(0xFF06B6D4),
    ),
    TrainingSchedule(
      title: '5 ngày/tuần',
      subtitle: 'Intermediate',
      description: 'Tốt cho người đã quen tập đều đặn.',
      icon: PhosphorIconsBold.barbell,
      color: Color(0xFFFFB545),
    ),
    TrainingSchedule(
      title: '6 ngày/tuần',
      subtitle: 'Advanced',
      description: 'Cường độ cao, cần ngủ và ăn uống tốt.',
      icon: PhosphorIconsBold.lightning,
      color: Color(0xFFC084FC),
    ),
    TrainingSchedule(
      title: '7 ngày/tuần',
      subtitle: 'Athlete',
      description: 'Chỉ nên dùng nếu có ngày tập nhẹ/phục hồi.',
      icon: PhosphorIconsBold.crown,
      color: Color(0xFFFF5C8A),
    ),
  ];

  Future<void> finishOnboarding() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

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
      await SessionStore.markProfileComplete();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể kết nối backend: $error')),
      );
      setState(() => _isSaving = false);
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
                        'Lịch tập luyện',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Chọn tần suất phù hợp với lối sống của bạn',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: const SizedBox(
                          height: 4,
                          child: LinearProgressIndicator(
                            value: 1.0,
                            backgroundColor: AppColors.outlineStrong,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      Column(
                        children: schedules.map((schedule) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ScheduleOptionCard(
                              schedule: schedule,
                              isSelected: selectedSchedule == schedule.title,
                              onTap: () => setState(
                                  () => selectedSchedule = schedule.title),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 8),
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
                              text: 'Bắt đầu ngay',
                              onTap: finishOnboarding,
                              loading: _isSaving,
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
