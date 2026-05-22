import 'package:flutter/material.dart';
import '../widgets/widgets.dart';
import 'onboarding_goal_screen.dart';

class OnboardingMetricsScreen extends StatefulWidget {
  final String email;
  final String name;
  final String gender;
  final String age;

  const OnboardingMetricsScreen({
    super.key,
    required this.email,
    required this.name,
    required this.gender,
    required this.age,
  });

  @override
  State<OnboardingMetricsScreen> createState() =>
      _OnboardingMetricsScreenState();
}

class _OnboardingMetricsScreenState extends State<OnboardingMetricsScreen> {
  final TextEditingController weightController = TextEditingController();
  final TextEditingController heightController = TextEditingController();

  double? bmi;

  @override
  void dispose() {
    weightController.dispose();
    heightController.dispose();
    super.dispose();
  }

  void calculateBMI() {
    final weight = double.tryParse(weightController.text.trim());
    final heightCm = double.tryParse(heightController.text.trim());

    if (weight == null || heightCm == null || heightCm <= 0) {
      setState(() {
        bmi = null;
      });
      return;
    }

    final heightM = heightCm / 100;
    final result = weight / (heightM * heightM);

    setState(() {
      bmi = result;
    });
  }

  String getBmiStatus() {
    if (bmi == null) return '';
    if (bmi! < 18.5) return 'Thiếu cân';
    if (bmi! < 25) return 'Bình thường';
    if (bmi! < 30) return 'Thừa cân';
    return 'Béo phì';
  }

  Color getBmiColor() {
    if (bmi == null) return Colors.white.withValues(alpha: 0.5);
    if (bmi! < 18.5) return Colors.orange;
    if (bmi! < 25) return const Color(0xFF12E67F);
    if (bmi! < 30) return Colors.amber;
    return Colors.redAccent;
  }

  void goNext() {
    FocusScope.of(context).unfocus();

    final weight = weightController.text.trim();
    final height = heightController.text.trim();

    if (weight.isEmpty || height.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập cân nặng và chiều cao')),
      );
      return;
    }

    // Thực hiện chuyển sang màn hình 3 (OnboardingGoalScreen)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OnboardingGoalScreen(
          email: widget.email,
          name: widget.name,
          gender: widget.gender,
          age: widget.age,
          weight: weight,
          height: height,
          bmi: bmi?.toStringAsFixed(1) ?? '--',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF171A21),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Phần nội dung có thể cuộn
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 36),
                    const AppLogo(),
                    const SizedBox(height: 24),
                    const Text(
                      'Welcome to GymSupport',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Hi ${widget.name}, let's track your physical metrics",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const StepIndicator(currentStep: 2, totalSteps: 3),
                    const SizedBox(height: 32),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Your body metrics',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const InputLabel(text: 'WEIGHT (KG)'),
                    const SizedBox(height: 8),
                    AppTextField(
                      controller: weightController,
                      hintText: '70',
                      suffixText: 'kg',
                      keyboardType: TextInputType.number,
                      onChanged: (_) => calculateBMI(),
                    ),
                    const SizedBox(height: 18),
                    const InputLabel(text: 'HEIGHT (CM)'),
                    const SizedBox(height: 8),
                    AppTextField(
                      controller: heightController,
                      hintText: '175',
                      suffixText: 'cm',
                      keyboardType: TextInputType.number,
                      onChanged: (_) => calculateBMI(),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2B2E38),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'BODY MASS INDEX (BMI)',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            bmi == null ? '--' : bmi!.toStringAsFixed(1),
                            style: TextStyle(
                              color: getBmiColor(),
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            bmi == null
                                ? 'Nhập thông số để tính BMI'
                                : getBmiStatus(),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // 2. Nút bấm cố định ở dưới cùng
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
              child: Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: SecondaryButton(
                      text: 'Back',
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(text: 'Continue', onTap: goNext),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
