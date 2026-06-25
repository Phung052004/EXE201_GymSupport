import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:gym_support/core/constants/app_colors.dart';
import 'package:gym_support/core/constants/app_images.dart';
import 'package:gym_support/core/constants/app_theme.dart';
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
    FocusManager.instance.primaryFocus?.unfocus();

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
      body: Column(
        children: [
          // Hero header with network image
          SizedBox(
            height: 220,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: AppImages.gymHero,
                  fit: BoxFit.cover,
                  placeholder: (ctx, url) => Container(color: AppColors.surface),
                  errorWidget: (ctx, url, err) => Container(
                    decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.25),
                        AppColors.background,
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20, left: 24, right: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              gradient: AppTheme.cyanGradient,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(PhosphorIconsBold.barbell,
                                color: AppColors.textDark, size: 16),
                          ),
                          const SizedBox(width: 8),
                          const Text('GymSupport',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              )),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chào mừng bạn!',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Hãy cá nhân hóa hành trình thể thao của bạn',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  StepIndicator(currentStep: 1, totalSteps: 3),
                  const SizedBox(height: 24),

                  if (!_hasRegisteredName) ...[
                    _Label('TÊN CỦA BẠN'),
                    const SizedBox(height: 8),
                    AppTextField(
                      controller: nameController,
                      hintText: 'Alex',
                      prefixIcon: PhosphorIconsRegular.user,
                    ),
                  ] else ...[
                    _Label('TÊN CỦA BẠN'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(PhosphorIconsBold.user,
                              color: AppColors.primary, size: 18),
                          const SizedBox(width: 10),
                          Text(nameController.text,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),
                  _Label('GIỚI TÍNH'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: GenderButton(
                        title: 'Nam', isSelected: selectedGender == 'Nam',
                        onTap: () => setState(() => selectedGender = 'Nam'))),
                      const SizedBox(width: 8),
                      Expanded(child: GenderButton(
                        title: 'Nữ', isSelected: selectedGender == 'Nữ',
                        onTap: () => setState(() => selectedGender = 'Nữ'))),
                      const SizedBox(width: 8),
                      Expanded(child: GenderButton(
                        title: 'Khác', isSelected: selectedGender == 'Khác',
                        onTap: () => setState(() => selectedGender = 'Khác'))),
                    ],
                  ),

                  const SizedBox(height: 18),
                  _Label('TUỔI (TÙY CHỌN)'),
                  const SizedBox(height: 8),
                  AppTextField(
                    controller: ageController,
                    hintText: '18',
                    keyboardType: TextInputType.number,
                    prefixIcon: PhosphorIconsRegular.calendar,
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: PrimaryButton(
              text: 'Tiếp tục',
              onTap: goNext,
              loading: _isNavigating,
            ),
          ),
        ],
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
