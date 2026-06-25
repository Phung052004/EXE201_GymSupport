import 'package:flutter/material.dart';

import 'package:gym_support/core/constants/app_colors.dart';
import 'package:gym_support/core/constants/app_theme.dart';
import 'package:gym_support/core/services/backend_api.dart';
import 'package:gym_support/core/services/session_store.dart';
import 'package:gym_support/features/main/screens/main_navigation_screen.dart';
import 'onboarding_name_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  bool isLoginMode = true;
  bool isLoading = false;
  bool _passwordVisible = false;
  bool _confirmVisible = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (isLoading) return;

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();
    final name = _nameCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _snack('Vui lòng nhập đủ thông tin');
      return;
    }
    if (!isLoginMode && confirm.isEmpty) {
      _snack('Vui lòng xác nhận mật khẩu');
      return;
    }
    if (!isLoginMode && password != confirm) {
      _snack('Mật khẩu xác nhận không khớp');
      return;
    }
    if (!isLoginMode && name.isEmpty) {
      _snack('Vui lòng nhập họ tên');
      return;
    }

    setState(() => isLoading = true);

    try {
      if (isLoginMode) {
        final res = await BackendApi.loginUser(email: email, password: password);
        await SessionStore.saveAuth(
          email: email,
          token: res['token']?.toString() ?? '',
          userId: res['userId']?.toString(),
          role: res['role']?.toString(),
          profileComplete: false,
        );
        final profile = await BackendApi.getOnboardingProfileByEmail(email);
        if (!mounted) return;

        await SessionStore.saveAuth(
          email: email,
          token: res['token']?.toString() ?? '',
          userId: res['userId']?.toString(),
          role: res['role']?.toString(),
          customerId: profile?['id']?.toString(),
          profileComplete: _isComplete(profile),
        );

        if (!_isComplete(profile)) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => OnboardingNameScreen(
                email: email,
                initialName: profile?['name']?.toString(),
              ),
            ),
          );
          return;
        }

        final p = profile!;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MainNavigationScreen(
              name: p['name']?.toString() ?? email,
              goal: p['goal']?.toString() ?? '',
              schedule: p['schedule']?.toString() ?? '',
              bmi: p['bmi']?.toString() ?? '--',
            ),
          ),
        );
      } else {
        await BackendApi.registerUser(
          email: email,
          password: password,
          confirmPassword: confirm,
          name: name,
        );
        await SessionStore.savePendingEmail(email);
        if (!mounted) return;
        setState(() {
          isLoginMode = true;
          _passwordCtrl.clear();
          _confirmCtrl.clear();
        });
        _snack('Tài khoản đã tạo! Xác minh email rồi đăng nhập.');
      }
    } catch (e) {
      if (!mounted) return;
      _snack('Lỗi: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  bool _isComplete(Map<String, dynamic>? p) {
    if (p == null) return false;
    return (p['goal']?.toString().trim() ?? '').isNotEmpty &&
        (p['weight']?.toString().trim() ?? '').isNotEmpty &&
        (p['height']?.toString().trim() ?? '').isNotEmpty;
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.surface3,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeroHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTabSwitcher(),
                  const SizedBox(height: 28),
                  _buildFormFields(),
                  const SizedBox(height: 28),
                  _buildSubmitButton(),
                  if (isLoginMode) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'Quên mật khẩu?',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF003D4D), Color(0xFF001820), AppColors.background],
          stops: [0.0, 0.65, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
          child: Column(
            children: [
              // Logo
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: AppTheme.cyanGradient,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.30),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.fitness_center_rounded,
                  color: AppColors.textDark,
                  size: 34,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'GymSupport',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your AI-powered fitness companion',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: isLoginMode ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: AppTheme.cyanGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => isLoginMode = true),
                  child: Center(
                    child: Text(
                      'Đăng nhập',
                      style: TextStyle(
                        color: isLoginMode ? AppColors.textDark : AppColors.textSecondary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => isLoginMode = false),
                  child: Center(
                    child: Text(
                      'Đăng ký',
                      style: TextStyle(
                        color: !isLoginMode ? AppColors.textDark : AppColors.textSecondary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildField(
            controller: _emailCtrl,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          _buildField(
            controller: _passwordCtrl,
            label: 'Mật khẩu',
            icon: Icons.lock_outline_rounded,
            obscure: !_passwordVisible,
            suffix: _visibilityToggle(
              visible: _passwordVisible,
              onToggle: () => setState(() => _passwordVisible = !_passwordVisible),
            ),
          ),
          if (!isLoginMode) ...[
            const SizedBox(height: 14),
            _buildField(
              controller: _confirmCtrl,
              label: 'Xác nhận mật khẩu',
              icon: Icons.lock_outline_rounded,
              obscure: !_confirmVisible,
              suffix: _visibilityToggle(
                visible: _confirmVisible,
                onToggle: () => setState(() => _confirmVisible = !_confirmVisible),
              ),
            ),
            const SizedBox(height: 14),
            _buildField(
              controller: _nameCtrl,
              label: 'Họ và tên',
              icon: Icons.person_outline_rounded,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _visibilityToggle({required bool visible, required VoidCallback onToggle}) {
    return IconButton(
      icon: Icon(
        visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: AppColors.textSecondary,
        size: 20,
      ),
      onPressed: onToggle,
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isLoading ? null : AppTheme.cyanGradient,
          color: isLoading ? AppColors.surface2 : null,
          borderRadius: BorderRadius.circular(14),
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            foregroundColor: AppColors.textDark,
            disabledForegroundColor: AppColors.textSecondary,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.textSecondary),
                  ),
                )
              : Text(
                  isLoginMode ? 'Đăng nhập' : 'Tạo tài khoản',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
        ),
      ),
    );
  }
}
