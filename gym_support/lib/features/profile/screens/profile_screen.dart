import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/services/backend_api.dart';
import '../../../core/services/session_store.dart';
import 'package:gym_support/features/ai_coach/screens/scan_equipment_screen.dart';
import '../../../screens/auth_screen.dart';
import '../../admin/screens/admin_dashboard_screen.dart';
import 'subscription_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String name;
  final String goal;
  final String schedule;
  final String bmi;
  final void Function(String goal, String schedule)? onGoalsUpdated;
  final ValueChanged<String>? onBmiUpdated;

  const ProfileScreen({
    super.key,
    required this.name,
    required this.goal,
    required this.schedule,
    required this.bmi,
    this.onGoalsUpdated,
    this.onBmiUpdated,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late String _goal;
  late String _schedule;
  late String _bmi;
  Map<String, dynamic>? _dashboard;
  List<Map<String, dynamic>> _badges = const [];
  List<Map<String, dynamic>> _weeklyStats  = const [];
  List<Map<String, dynamic>> _monthlyStats = const [];
  bool _dashLoading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _goal = widget.goal;
    _schedule = widget.schedule;
    _bmi = widget.bmi;
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString(SessionStore.emailKey) ?? '';
      if (email.isEmpty) return;
      final role = prefs.getString(SessionStore.roleKey) ?? '';
      final results = await Future.wait([
        BackendApi.getDashboardSummary(email),
        BackendApi.getUserBadges(),
        BackendApi.getWeeklyStats(weeks: 8),
        BackendApi.getMonthlyStats(months: 6),
      ]);
      if (!mounted) return;
      setState(() {
        _dashboard    = results[0] as Map<String, dynamic>?;
        _badges       = (results[1] as List?)?.whereType<Map<String, dynamic>>().toList() ?? const [];
        _weeklyStats  = (results[2] as List?)?.whereType<Map<String, dynamic>>().toList() ?? const [];
        _monthlyStats = (results[3] as List?)?.whereType<Map<String, dynamic>>().toList() ?? const [];
        _isAdmin      = role.toLowerCase() == 'admin';
        _dashLoading  = false;
      });
    } catch (_) {
      if (mounted) setState(() => _dashLoading = false);
    }
  }

  Future<String> _currentEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(SessionStore.emailKey) ?? '';
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Đăng xuất?',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900),
        ),
        content: const Text(
          'Bạn có chắc muốn đăng xuất khỏi GymSupport không?',
          style: TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final nav = Navigator.of(context);
              await SessionStore.clear();
              nav.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthScreen()),
                (route) => false,
              );
            },
            child: const Text('Đăng xuất', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Future<void> _openScanEquipment() async {
    final email = await _currentEmail();
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ScanEquipmentScreen(email: email)),
    );
  }

  void _showProfileInfoSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => FutureBuilder<Map<String, dynamic>?>(
        future: _loadProfileInfo(),
        builder: (ctx, snapshot) {
          final profile = snapshot.data;
          return _ProfileInfoSheet(
            name: widget.name,
            weight: profile?['weight']?.toString() ?? '--',
            height: profile?['height']?.toString() ?? '--',
            bmi: _bmi,
            onEditTap: () {
              Navigator.pop(ctx);
              _showEditBodyMetricsSheet(profile);
            },
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>?> _loadProfileInfo() async {
    final email = await _currentEmail();
    if (email.isEmpty) return null;
    return BackendApi.getOnboardingProfileByEmail(email);
  }

  void _showEditBodyMetricsSheet(Map<String, dynamic>? profile) {
    final weightCtrl = TextEditingController(text: profile?['weight']?.toString() ?? '');
    final heightCtrl = TextEditingController(text: profile?['height']?.toString() ?? '');
    var saving = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Cập nhật thể trạng', style: AppTheme.headlineSmall),
              const SizedBox(height: 20),
              _buildTextField(controller: weightCtrl, label: 'Cân nặng (kg)', keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _buildTextField(controller: heightCtrl, label: 'Chiều cao (cm)', keyboardType: TextInputType.number),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: saving ? null : AppTheme.cyanGradient,
                    color: saving ? AppColors.surface2 : null,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            setSheetState(() => saving = true);
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              final result = await BackendApi.updateBodyMetrics(
                                weight: weightCtrl.text.trim(),
                                height: heightCtrl.text.trim(),
                              );
                              if (!mounted || !ctx.mounted) return;
                              Navigator.pop(ctx);
                              widget.onBmiUpdated?.call(result['bmi']?.toString() ?? _bmi);
                              setState(() => _bmi = result['bmi']?.toString() ?? _bmi);
                              messenger.showSnackBar(
                                const SnackBar(content: Text('Cập nhật thành công!')),
                              );
                            } catch (e) {
                              setSheetState(() => saving = false);
                              messenger.showSnackBar(
                                SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.danger),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      disabledBackgroundColor: Colors.transparent,
                      foregroundColor: AppColors.textDark,
                      disabledForegroundColor: AppColors.textSecondary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                    child: saving
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: AppColors.textSecondary, strokeWidth: 2))
                        : const Text('Lưu thay đổi', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGoalsSheet() {
    var selectedGoal = _goal;
    var selectedSchedule = _schedule;
    var saving = false;

    const goals = ['Tăng cơ', 'Giảm mỡ', 'Tăng sức mạnh', 'Duy trì sức khỏe'];
    const schedules = ['Mới bắt đầu', 'Trung cấp', 'Nâng cao'];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.outline, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Mục tiêu & Trình độ', style: AppTheme.headlineSmall),
              const SizedBox(height: 20),
              const Text('Mục tiêu', style: AppTheme.labelLarge),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: goals.map((g) => AppChip(
                  label: g,
                  selected: selectedGoal == g,
                  onTap: () => setSheetState(() => selectedGoal = g),
                )).toList(),
              ),
              const SizedBox(height: 20),
              const Text('Trình độ', style: AppTheme.labelLarge),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: schedules.map((s) => AppChip(
                  label: s,
                  selected: selectedSchedule == s,
                  onTap: () => setSheetState(() => selectedSchedule = s),
                )).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: saving ? null : AppTheme.cyanGradient,
                    color: saving ? AppColors.surface2 : null,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          setSheetState(() => saving = true);
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            final email = await _currentEmail();
                            await BackendApi.updateOnboardingProfile(
                              email: email,
                              goal: selectedGoal,
                              schedule: selectedSchedule,
                            );
                            if (!mounted || !ctx.mounted) return;
                            Navigator.pop(ctx);
                            setState(() { _goal = selectedGoal; _schedule = selectedSchedule; });
                            widget.onGoalsUpdated?.call(selectedGoal, selectedSchedule);
                          } catch (e) {
                            setSheetState(() => saving = false);
                            messenger.showSnackBar(
                              SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.danger),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    disabledBackgroundColor: Colors.transparent,
                    foregroundColor: AppColors.textDark,
                    disabledForegroundColor: AppColors.textSecondary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                  child: saving
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: AppColors.textSecondary, strokeWidth: 2))
                      : const Text('Lưu thay đổi', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initials = widget.name.isNotEmpty
        ? widget.name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : 'U';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    const Expanded(child: Text('Hồ sơ', style: AppTheme.displaySmall)),
                    GestureDetector(
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Settings sẽ sớm ra mắt')),
                      ),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(color: AppColors.outline),
                        ),
                        child: const Icon(PhosphorIconsRegular.gear, color: AppColors.textSecondary, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Avatar + name
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                child: Column(
                  children: [
                    // Avatar with cyan gradient + glow
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        gradient: AppTheme.cyanGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 28,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      widget.name.isEmpty ? 'Người dùng' : widget.name,
                      style: AppTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _goal.isEmpty ? 'Chưa đặt mục tiêu' : _goal,
                      style: AppTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            // Stats row
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Row(
                  children: [
                    _buildStatCard(
                      icon: PhosphorIconsBold.trophy,
                      color: AppColors.primary,
                      value: _dashLoading ? '–' : '${_dashboard?['workoutCount'] ?? 0}',
                      label: 'Buổi tập',
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      icon: PhosphorIconsBold.calendarCheck,
                      color: AppColors.violet,
                      value: _dashLoading ? '–' : '${_dashboard?['planCount'] ?? 0}',
                      label: 'Kế hoạch',
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      icon: PhosphorIconsBold.scales,
                      color: AppColors.blue,
                      value: _bmi.isEmpty ? '–' : (double.tryParse(_bmi)?.toStringAsFixed(1) ?? _bmi),
                      label: 'BMI',
                    ),
                  ],
                ),
              ),
            ),
            // Badges
            if (!_dashLoading)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'HUY HIỆU',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_badges.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.gold.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Text(
                                '${_badges.length}',
                                style: const TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_badges.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            border: Border.all(color: AppColors.outline),
                          ),
                          child: const Column(
                            children: [
                              Text('🏅', style: TextStyle(fontSize: 28)),
                              SizedBox(height: 8),
                              Text(
                                'Chưa có huy hiệu nào',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Tập liên tiếp để nhận badge streak!',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _badges.map((b) => _BadgeChip(badge: b)).toList(),
                        ),
                    ],
                  ),
                ),
              ),
            // Stats section
            if (!_dashLoading)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: _StatsSection(
                    weeklyStats: _weeklyStats,
                    monthlyStats: _monthlyStats,
                  ),
                ),
              ),
            // Menu items
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TÀI KHOẢN',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMenuGroup([
                      _ProfileMenuItem(
                        icon: PhosphorIconsRegular.user,
                        label: 'Thông tin cá nhân',
                        onTap: _showProfileInfoSheet,
                      ),
                      _ProfileMenuItem(
                        icon: PhosphorIconsRegular.flag,
                        label: 'Mục tiêu & Trình độ',
                        subtitle: _goal.isEmpty ? null : _goal,
                        onTap: _showGoalsSheet,
                      ),
                      _ProfileMenuItem(
                        icon: PhosphorIconsRegular.crown,
                        label: 'Premium',
                        badge: 'Nâng cấp',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 20),
                    const Text(
                      'CÔNG CỤ',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMenuGroup([
                      _ProfileMenuItem(
                        icon: PhosphorIconsRegular.camera,
                        label: 'Quét thiết bị AI',
                        onTap: _openScanEquipment,
                      ),
                      _ProfileMenuItem(
                        icon: PhosphorIconsRegular.bell,
                        label: 'Thông báo',
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sẽ sớm ra mắt')),
                        ),
                      ),
                    ]),
                    // Admin panel — only visible to admins
                    if (_isAdmin) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'QUẢN TRỊ',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildMenuGroup([
                        _ProfileMenuItem(
                          icon: PhosphorIconsRegular.shieldStar,
                          label: 'Admin Dashboard',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AdminDashboardScreen(),
                            ),
                          ),
                        ),
                      ]),
                    ],
                    const SizedBox(height: 20),
                    // Logout button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _showLogoutDialog,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                            border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(PhosphorIconsBold.signOut, color: AppColors.danger, size: 20),
                              SizedBox(width: 10),
                              Text(
                                'Đăng xuất',
                                style: TextStyle(
                                  color: AppColors.danger,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppColors.outline),
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 3),
            Text(label, style: AppTheme.caption, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuGroup(List<Widget> items) {
    return Container(
      decoration: AppTheme.cardDecoration(),
      child: Column(
        children: items.asMap().entries.map((e) {
          final isLast = e.key == items.length - 1;
          return Column(
            children: [
              e.value,
              if (!isLast)
                const Divider(color: AppColors.outline, height: 1, indent: 56),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final String? badge;
  final VoidCallback? onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    this.subtitle,
    this.badge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.textSecondary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTheme.titleMedium),
                    if (subtitle != null)
                      Text(subtitle!, style: AppTheme.caption),
                  ],
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              const Icon(PhosphorIconsBold.caretRight, color: AppColors.textSecondary, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileInfoSheet extends StatelessWidget {
  final String name;
  final String weight;
  final String height;
  final String bmi;
  final VoidCallback? onEditTap;

  const _ProfileInfoSheet({
    required this.name,
    required this.weight,
    required this.height,
    required this.bmi,
    this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Thông tin cá nhân', style: AppTheme.headlineSmall),
          const SizedBox(height: 20),
          _InfoRow(label: 'Tên', value: name),
          const Divider(color: AppColors.outline, height: 24),
          _InfoRow(label: 'Cân nặng', value: '$weight kg'),
          const Divider(color: AppColors.outline, height: 24),
          _InfoRow(label: 'Chiều cao', value: '$height cm'),
          const Divider(color: AppColors.outline, height: 24),
          _InfoRow(label: 'BMI', value: bmi.isEmpty ? '--' : double.tryParse(bmi)?.toStringAsFixed(1) ?? bmi),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: onEditTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Chỉnh sửa cân nặng / chiều cao'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTheme.bodyMedium),
        Text(value, style: AppTheme.titleMedium),
      ],
    );
  }
}

class _StatsSection extends StatefulWidget {
  final List<Map<String, dynamic>> weeklyStats;
  final List<Map<String, dynamic>> monthlyStats;

  const _StatsSection({required this.weeklyStats, required this.monthlyStats});

  @override
  State<_StatsSection> createState() => _StatsSectionState();
}

class _StatsSectionState extends State<_StatsSection> {
  bool _showMonthly = false;

  @override
  Widget build(BuildContext context) {
    final stats = _showMonthly ? widget.monthlyStats : widget.weeklyStats;
    final maxSessions = stats.isEmpty
        ? 1
        : stats.map((s) => (s['sessionCount'] as num?)?.toDouble() ?? 0).reduce((a, b) => a > b ? a : b);

    // This week vs last week comparison
    final thisWeek = widget.weeklyStats.isNotEmpty ? widget.weeklyStats.last : null;
    final lastWeek = widget.weeklyStats.length >= 2 ? widget.weeklyStats[widget.weeklyStats.length - 2] : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'THỐNG KÊ',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            _ToggleTab(
              label: 'Tuần',
              selected: !_showMonthly,
              onTap: () => setState(() => _showMonthly = false),
            ),
            const SizedBox(width: 6),
            _ToggleTab(
              label: 'Tháng',
              selected: _showMonthly,
              onTap: () => setState(() => _showMonthly = true),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // This week vs last week quick comparison
        if (!_showMonthly && thisWeek != null)
          _WeekCompareRow(thisWeek: thisWeek, lastWeek: lastWeek),

        if (!_showMonthly && thisWeek != null) const SizedBox(height: 12),

        // Bar chart
        if (stats.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppColors.outline),
            ),
            child: const Center(
              child: Text('Chưa có dữ liệu', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppColors.outline),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 80,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: stats.map((s) {
                      final count = (s['sessionCount'] as num?)?.toDouble() ?? 0;
                      final ratio = maxSessions > 0 ? count / maxSessions : 0.0;
                      final isLast = s == stats.last;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (count > 0)
                                Text(
                                  '${count.toInt()}',
                                  style: TextStyle(
                                    color: isLast ? AppColors.primary : AppColors.textTertiary,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              const SizedBox(height: 2),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                height: (ratio * 56).clamp(3, 56),
                                decoration: BoxDecoration(
                                  color: isLast
                                      ? AppColors.primary
                                      : AppColors.primary.withValues(alpha: 0.28),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: stats.map((s) {
                    final label = (s['label'] as String?) ?? '';
                    final isLast = s == stats.last;
                    return Expanded(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isLast ? AppColors.primary : AppColors.textTertiary,
                          fontSize: 9,
                          fontWeight: isLast ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

        // Monthly totals row
        if (_showMonthly && stats.isNotEmpty) ...[
          const SizedBox(height: 10),
          _MonthSummaryRow(current: stats.last),
        ],
      ],
    );
  }
}

class _ToggleTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleTab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary.withValues(alpha: 0.5) : AppColors.outline,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.primary : AppColors.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _WeekCompareRow extends StatelessWidget {
  final Map<String, dynamic> thisWeek;
  final Map<String, dynamic>? lastWeek;

  const _WeekCompareRow({required this.thisWeek, this.lastWeek});

  @override
  Widget build(BuildContext context) {
    final thisSessions = (thisWeek['sessionCount'] as num?)?.toInt() ?? 0;
    final lastSessions = (lastWeek?['sessionCount'] as num?)?.toInt() ?? 0;
    final thisMin      = (thisWeek['totalDurationMinutes'] as num?)?.toInt() ?? 0;
    final lastMin      = (lastWeek?['totalDurationMinutes'] as num?)?.toInt() ?? 0;
    final thisSets     = (thisWeek['totalSets'] as num?)?.toInt() ?? 0;
    final lastSets     = (lastWeek?['totalSets'] as num?)?.toInt() ?? 0;

    return Row(
      children: [
        _CompareCell(label: 'Buổi tập', current: thisSessions, previous: lastSessions, suffix: ''),
        const SizedBox(width: 8),
        _CompareCell(label: 'Thời gian', current: thisMin, previous: lastMin, suffix: 'ph'),
        const SizedBox(width: 8),
        _CompareCell(label: 'Tổng sets', current: thisSets, previous: lastSets, suffix: ''),
      ],
    );
  }
}

class _CompareCell extends StatelessWidget {
  final String label;
  final int current;
  final int previous;
  final String suffix;

  const _CompareCell({
    required this.label,
    required this.current,
    required this.previous,
    required this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final diff = current - previous;
    final Color trendColor = diff > 0
        ? AppColors.success
        : diff < 0
            ? AppColors.danger
            : AppColors.textTertiary;
    final String trendStr = diff > 0
        ? '+$diff'
        : diff < 0
            ? '$diff'
            : '=';

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppColors.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$current${suffix.isNotEmpty ? suffix : ''}',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                Text(
                  trendStr,
                  style: TextStyle(color: trendColor, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthSummaryRow extends StatelessWidget {
  final Map<String, dynamic> current;

  const _MonthSummaryRow({required this.current});

  @override
  Widget build(BuildContext context) {
    final sessions = (current['sessionCount'] as num?)?.toInt() ?? 0;
    final minutes  = (current['totalDurationMinutes'] as num?)?.toInt() ?? 0;
    final sets     = (current['totalSets'] as num?)?.toInt() ?? 0;
    final exp      = (current['totalExpGained'] as num?)?.toInt() ?? 0;
    final label    = current['label']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tháng $label',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _MiniStat(value: '$sessions', label: 'Buổi'),
              _MiniStat(value: '${minutes}ph', label: 'Tổng g.'),
              _MiniStat(value: '$sets', label: 'Sets'),
              _MiniStat(value: '+$exp', label: 'EXP'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;

  const _MiniStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppColors.textTertiary, fontSize: 10)),
        ],
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final Map<String, dynamic> badge;

  const _BadgeChip({required this.badge});

  @override
  Widget build(BuildContext context) {
    final emoji = badge['emoji']?.toString() ?? '🏆';
    final name = badge['name']?.toString() ?? '';
    final description = badge['description']?.toString() ?? '';

    return Tooltip(
      message: description,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              name,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
