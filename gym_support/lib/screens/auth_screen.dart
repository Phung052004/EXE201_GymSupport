import 'package:flutter/material.dart';

import 'package:gym_support/core/constants/app_colors.dart';
import 'package:gym_support/core/services/backend_api.dart';
import 'package:gym_support/core/services/session_store.dart';
import 'package:gym_support/features/main/screens/main_navigation_screen.dart';
import 'onboarding_name_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController nameController = TextEditingController();

  bool isLoginMode = true;
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nameController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (isLoading) return;

    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();
    final name = nameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đủ thông tin')),
      );
      return;
    }

    if (!isLoginMode && confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng xác nhận mật khẩu')),
      );
      return;
    }

    if (!isLoginMode && password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu xác nhận không khớp')),
      );
      return;
    }

    if (!isLoginMode && name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đủ thông tin')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      if (isLoginMode) {
        final loginResponse = await BackendApi.loginUser(
          email: email,
          password: password,
        );
        await SessionStore.saveAuth(
          email: email,
          token: loginResponse['token']?.toString() ?? '',
          userId: loginResponse['userId']?.toString(),
          role: loginResponse['role']?.toString(),
          profileComplete: false,
        );
        final profile = await BackendApi.getOnboardingProfileByEmail(email);
        if (!mounted) return;

        await SessionStore.saveAuth(
          email: email,
          token: loginResponse['token']?.toString() ?? '',
          userId: loginResponse['userId']?.toString(),
          role: loginResponse['role']?.toString(),
          customerId: profile?['id']?.toString(),
          profileComplete: _isProfileComplete(profile),
        );

        if (!_isProfileComplete(profile)) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OnboardingNameScreen(
                email: email,
                initialName: profile?['name']?.toString(),
              ),
            ),
          );
          return;
        }

        final completeProfile = profile!;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainNavigationScreen(
              name: completeProfile['name']?.toString() ?? email,
              goal: completeProfile['goal']?.toString() ?? '',
              schedule: completeProfile['schedule']?.toString() ?? '',
              bmi: completeProfile['bmi']?.toString() ?? '--',
            ),
          ),
        );
      } else {
        await BackendApi.registerUser(
          email: email,
          password: password,
          confirmPassword: confirmPassword,
          name: name,
        );
        await SessionStore.savePendingEmail(email);

        if (!mounted) return;
        setState(() {
          isLoginMode = true;
          passwordController.clear();
          confirmPasswordController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Đã tạo tài khoản. Hãy xác minh email rồi đăng nhập.',
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể kết nối backend: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  bool _isProfileComplete(Map<String, dynamic>? profile) {
    if (profile == null) return false;
    final goal = profile['goal']?.toString().trim() ?? '';
    final weight = profile['weight']?.toString().trim() ?? '';
    final height = profile['height']?.toString().trim() ?? '';
    return goal.isNotEmpty && weight.isNotEmpty && height.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                const Icon(
                  Icons.fitness_center,
                  color: AppColors.primary,
                  size: 56,
                ),
                const SizedBox(height: 16),
                const Text(
                  'GymSupport',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isLoginMode ? 'Đăng nhập để tiếp tục' : 'Tạo tài khoản mới',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 28),
                ToggleButtons(
                  isSelected: [isLoginMode, !isLoginMode],
                  onPressed: (index) {
                    setState(() {
                      isLoginMode = index == 0;
                    });
                  },
                  borderRadius: BorderRadius.circular(14),
                  selectedColor: AppColors.textDark,
                  fillColor: AppColors.primary,
                  borderColor: Colors.white.withValues(alpha: 0.08),
                  selectedBorderColor: AppColors.primary,
                  color: Colors.white.withValues(alpha: 0.72),
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18),
                      child: Text('Login'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18),
                      child: Text('Register'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration('Email'),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: _inputDecoration('Password'),
                  style: const TextStyle(color: Colors.white),
                ),
                if (!isLoginMode) ...[
                  const SizedBox(height: 14),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: _inputDecoration('Confirm Password'),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nameController,
                    decoration: _inputDecoration('Full name'),
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : submit,
                    child: Text(
                      isLoading
                          ? 'Please wait...'
                          : (isLoginMode ? 'Login' : 'Create account'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
      filled: true,
      fillColor: AppColors.background,
    );
  }
}
