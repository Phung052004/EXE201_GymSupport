import 'package:flutter/material.dart';
import 'package:gym_support/core/constants/app_colors.dart';
import '../widgets/widgets.dart';
import 'onboarding_metrics_screen.dart';

class OnboardingNameScreen extends StatefulWidget {
  final String email;
  final String? initialName;

  const OnboardingNameScreen({
    super.key,
    required this.email,
    this.initialName,
  });

  @override
  State<OnboardingNameScreen> createState() => _OnboardingNameScreenState();
}

class _OnboardingNameScreenState extends State<OnboardingNameScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  String selectedGender = 'Nam';
  bool _isNavigating = false;
  bool get _hasRegisteredName => (widget.initialName ?? '').trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_hasRegisteredName) {
      nameController.text = widget.initialName!.trim();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    super.dispose();
  }

  void goNext() {
    if (_isNavigating) return;

    final name = nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên của bạn')),
      );
      return;
    }

    setState(() => _isNavigating = true);

    // Dismiss keyboard safely
    FocusManager.instance.primaryFocus?.unfocus();

    // Small delay to let the keyboard hide and layout stabilize
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OnboardingMetricsScreen(
            email: widget.email,
            name: name,
            gender: selectedGender,
            age: ageController.text.trim(),
          ),
        ),
      ).then((_) {
        if (mounted) setState(() => _isNavigating = false);
      });
    });
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
                  children: [
                    const SizedBox(height: 36),
                    const AppLogo(),
                    const SizedBox(height: 24),
                    const Text(
                      'Welcome to GymSupport',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Let's personalize your fitness journey",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 28),
                    const StepIndicator(currentStep: 1, totalSteps: 3),
                    const SizedBox(height: 32),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Tell us about yourself',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (!_hasRegisteredName) ...[
                      const InputLabel(text: 'YOUR NAME'),
                      const SizedBox(height: 8),
                      AppTextField(
                        controller: nameController,
                        hintText: 'Alex',
                      ),
                      const SizedBox(height: 18),
                    ] else ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.person_outline,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                nameController.text,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                    const InputLabel(text: 'GENDER'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GenderButton(
                            title: 'Nam',
                            isSelected: selectedGender == 'Nam',
                            onTap: () => setState(() => selectedGender = 'Nam'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GenderButton(
                            title: 'Nữ',
                            isSelected: selectedGender == 'Nữ',
                            onTap: () => setState(() => selectedGender = 'Nữ'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GenderButton(
                            title: 'Khác',
                            isSelected: selectedGender == 'Khác',
                            onTap: () =>
                                setState(() => selectedGender = 'Khác'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const InputLabel(text: 'AGE (OPTIONAL)'),
                    const SizedBox(height: 8),
                    AppTextField(
                      controller: ageController,
                      hintText: '18',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: PrimaryButton(text: 'Continue', onTap: goNext),
            ),
          ],
        ),
      ),
    );
  }
}
