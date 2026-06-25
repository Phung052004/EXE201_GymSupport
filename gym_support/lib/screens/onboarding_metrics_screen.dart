import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:gym_support/core/constants/app_colors.dart';
import 'package:gym_support/core/constants/app_theme.dart';
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
      setState(() => bmi = null);
      return;
    }
    final heightM = heightCm / 100;
    setState(() => bmi = weight / (heightM * heightM));
  }

  String getBmiStatus() {
    if (bmi == null) return '';
    if (bmi! < 18.5) return 'Thiếu cân';
    if (bmi! < 25) return 'Bình thường';
    if (bmi! < 30) return 'Thừa cân';
    return 'Béo phì';
  }

  Color getBmiColor() {
    if (bmi == null) return AppColors.textSecondary;
    if (bmi! < 18.5) return Colors.orange;
    if (bmi! < 25) return const Color(0xFF12E67F);
    if (bmi! < 30) return Colors.amber;
    return Colors.redAccent;
  }

  IconData getBmiIcon() {
    if (bmi == null) return PhosphorIconsRegular.scales;
    if (bmi! < 18.5) return PhosphorIconsBold.arrowDown;
    if (bmi! < 25) return PhosphorIconsBold.checkCircle;
    if (bmi! < 30) return PhosphorIconsBold.arrowUp;
    return PhosphorIconsBold.warning;
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
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),
                    Text(
                      'Xin chào, ${widget.name}!',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Cho chúng tôi biết thêm về chỉ số cơ thể của bạn',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    StepIndicator(currentStep: 2, totalSteps: 3),
                    const SizedBox(height: 28),

                    _Label('CÂN NẶNG (KG)'),
                    const SizedBox(height: 8),
                    AppTextField(
                      controller: weightController,
                      hintText: '70',
                      suffixText: 'kg',
                      keyboardType: TextInputType.number,
                      prefixIcon: PhosphorIconsRegular.scales,
                      onChanged: (_) => calculateBMI(),
                    ),

                    const SizedBox(height: 18),
                    _Label('CHIỀU CAO (CM)'),
                    const SizedBox(height: 8),
                    AppTextField(
                      controller: heightController,
                      hintText: '175',
                      suffixText: 'cm',
                      keyboardType: TextInputType.number,
                      prefixIcon: PhosphorIconsRegular.ruler,
                      onChanged: (_) => calculateBMI(),
                    ),

                    const SizedBox(height: 24),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: bmi != null ? AppTheme.heroGradient : null,
                        color: bmi != null ? null : AppColors.surface,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        border: Border.all(
                          color: bmi != null
                              ? AppColors.primary.withValues(alpha: 0.4)
                              : AppColors.outline,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52, height: 52,
                            decoration: BoxDecoration(
                              color: bmi != null
                                  ? getBmiColor().withValues(alpha: 0.15)
                                  : AppColors.surface2,
                              borderRadius: BorderRadius.circular(14),
                              border: bmi != null
                                  ? Border.all(color: getBmiColor().withValues(alpha: 0.3))
                                  : null,
                            ),
                            child: Icon(getBmiIcon(),
                                color: bmi != null
                                    ? getBmiColor()
                                    : AppColors.textTertiary,
                                size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('CHỈ SỐ BMI',
                                    style: TextStyle(
                                      color: AppColors.textTertiary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1,
                                    )),
                                const SizedBox(height: 4),
                                Text(
                                  bmi == null ? '--' : bmi!.toStringAsFixed(1),
                                  style: TextStyle(
                                    color: bmi != null
                                        ? getBmiColor()
                                        : AppColors.textSecondary,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  bmi == null
                                      ? 'Nhập thông số để tính BMI'
                                      : getBmiStatus(),
                                  style: TextStyle(
                                    color: bmi != null
                                        ? getBmiColor()
                                        : AppColors.textTertiary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Row(
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
                    child: PrimaryButton(text: 'Tiếp tục', onTap: goNext),
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

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textTertiary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}
