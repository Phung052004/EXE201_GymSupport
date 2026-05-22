import 'package:flutter/material.dart';

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
  final TextEditingController nameController = TextEditingController();

  bool isLoginMode = true;
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (isLoading) return;

    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final name = nameController.text.trim();

    if (email.isEmpty || password.isEmpty || (!isLoginMode && name.isEmpty)) {
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
        final profile = await BackendApi.getOnboardingProfileByEmail(email);
        if (!mounted) return;

        await SessionStore.saveAuth(
          email: email,
          token: loginResponse['token']?.toString() ?? '',
          profileComplete: profile != null,
        );

        if (profile == null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OnboardingNameScreen(email: email),
            ),
          );
          return;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainNavigationScreen(
              name: profile['name']?.toString() ?? email,
              goal: profile['goal']?.toString() ?? '',
              schedule: profile['schedule']?.toString() ?? '',
              bmi: profile['bmi']?.toString() ?? '--',
            ),
          ),
        );
      } else {
        await BackendApi.registerUser(
          email: email,
          password: password,
          name: name,
        );
        await SessionStore.savePendingEmail(email);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OnboardingNameScreen(email: email),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Icon(
                Icons.fitness_center,
                color: Color(0xFF12E67F),
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
                selectedColor: const Color(0xFF111318),
                fillColor: const Color(0xFF12E67F),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF12E67F),
                    foregroundColor: const Color(0xFF111318),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
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
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
      filled: true,
      fillColor: const Color(0xFF2B2E38),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }
}
