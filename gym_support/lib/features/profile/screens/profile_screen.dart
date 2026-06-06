import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/backend_api.dart';
import '../../../core/services/session_store.dart';
import 'package:gym_support/features/ai_coach/screens/generate_plan_screen.dart';
import 'package:gym_support/features/ai_coach/screens/scan_equipment_screen.dart';
import '../../../screens/auth_screen.dart';
import '../widgets/logout_button.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_menu_item.dart';
import '../widgets/profile_stat_card.dart';

class ProfileScreen extends StatefulWidget {
  final String name;
  final String goal;
  final String schedule;
  final String bmi;
  final void Function(String goal, String schedule)? onGoalsUpdated;

  const ProfileScreen({
    super.key,
    required this.name,
    required this.goal,
    required this.schedule,
    required this.bmi,
    this.onGoalsUpdated,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late String _goal;
  late String _schedule;
  late final Future<Map<String, dynamic>> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _goal = widget.goal;
    _schedule = widget.schedule;
    _dashboardFuture = _loadDashboard();
  }

  void showComingSoon(BuildContext context, String featureName) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$featureName sẽ làm ở bước sau')));
  }

  void showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Đăng xuất?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          ),
          content: Text(
            'Bạn có chắc muốn đăng xuất khỏi GymSupport không?',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Hủy',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final navigator = Navigator.of(context);
                await SessionStore.clear();

                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                  (route) => false,
                );
              },
              child: const Text(
                'Đăng xuất',
                style: TextStyle(
                  color: Color(0xFFFF4D6D),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>> _loadDashboard() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(SessionStore.emailKey);
    if (email == null || email.isEmpty) {
      return <String, dynamic>{};
    }

    return BackendApi.getDashboardSummary(email);
  }

  Future<String> _currentEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(SessionStore.emailKey) ?? '';
  }

  Future<void> _openGeneratePlan() async {
    try {
      final email = await _currentEmail();
      Map<String, dynamic>? profile;
      if (email.isNotEmpty) {
        profile = await BackendApi.getOnboardingProfileByEmail(email);
      }
      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => GeneratePlanScreen(
            email: email,
            name: profile?['name']?.toString() ?? widget.name,
            gender: profile?['gender']?.toString() ?? '',
            age: profile?['age']?.toString() ?? '',
            weight: profile?['weight']?.toString() ?? '',
            height: profile?['height']?.toString() ?? '',
            goal: profile?['goal']?.toString() ?? _goal,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tải được hồ sơ AI plan: $error')),
      );
    }
  }

  Future<void> _openScanEquipment() async {
    final email = await _currentEmail();
    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ScanEquipmentScreen(email: email)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProfileTopBar(
              onSettingsTap: () {
                showComingSoon(context, 'Settings');
              },
            ),
            const SizedBox(height: 18),
            Center(child: ProfileHeader(name: widget.name)),
            const SizedBox(height: 28),
            FutureBuilder<Map<String, dynamic>>(
              future: _dashboardFuture,
              builder: (context, snapshot) {
                final dashboard = snapshot.data ?? const <String, dynamic>{};
                final workoutCount =
                    dashboard['workoutCount']?.toString() ?? '0';
                final planCount = dashboard['planCount']?.toString() ?? '0';

                return Row(
                  children: [
                    Expanded(
                      child: ProfileStatCard(
                        icon: Icons.emoji_events,
                        iconColor: AppColors.primary,
                        value: workoutCount,
                        label: 'TOTAL WORKOUTS',
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ProfileStatCard(
                        icon: Icons.camera_alt_outlined,
                        iconColor: const Color(0xFFFF7A30),
                        value: planCount,
                        label: 'WORKOUT PLANS',
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),
            Text(
              'SETTINGS & PREFERENCES',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.32),
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 14),
            ProfileMenuItem(
              icon: Icons.person_outline,
              title: 'Personal Information',
              onTap: () {
                showProfileInfoBottomSheet(context);
              },
            ),
            ProfileMenuItem(
              icon: Icons.fitness_center,
              title: 'AI Workout Plan',
              onTap: _openGeneratePlan,
            ),
            ProfileMenuItem(
              icon: Icons.local_fire_department_outlined,
              title: 'Goals & Targets',
              onTap: () {
                showGoalsBottomSheet(context);
              },
            ),
            ProfileMenuItem(
              icon: Icons.camera_alt_outlined,
              title: 'Scan Equipment',
              onTap: _openScanEquipment,
            ),
            const SizedBox(height: 14),
            LogoutButton(
              onTap: () {
                showLogoutDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void showProfileInfoBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return ProfileInfoSheet(
          title: 'Personal Information',
          items: [
            InfoRow(label: 'Name', value: widget.name),
            InfoRow(
              label: 'BMI',
              value: widget.bmi.isEmpty ? '--' : widget.bmi,
            ),
          ],
        );
      },
    );
  }

  void showWorkoutPreferencesBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return ProfileInfoSheet(
          title: 'Workout Preferences',
          items: [
            InfoRow(label: 'Schedule', value: _schedule),
            const InfoRow(label: 'Level', value: 'Beginner'),
          ],
        );
      },
    );
  }

  void showGoalsBottomSheet(BuildContext context) {
    final goals = _goal
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return ProfileInfoSheet(
          title: 'Goals & Targets',
          items: [
            ...goals.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return InfoRow(
                label: index == 0 ? 'Main Goal' : 'Goal ${index + 1}',
                value: item,
              );
            }),
            InfoRow(label: 'Schedule', value: _schedule),
          ],
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showEditGoalsSheet(context);
              },
              child: const Text(
                'Chỉnh sửa mục tiêu',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEditGoalsSheet(BuildContext context) {
    final controller = TextEditingController(text: _goal);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            22,
            22,
            22,
            22 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chỉnh sửa Goals',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Ví dụ: Tăng cơ, Giảm mỡ, Cải thiện sức bền',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.04),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final value = controller.text.trim();
                        if (value.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vui lòng nhập mục tiêu'),
                            ),
                          );
                          return;
                        }
                        Navigator.pop(context);
                        _saveGoals(value);
                      },
                      child: const Text('Lưu'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ).whenComplete(controller.dispose);
  }

  Future<void> _saveGoals(String updatedGoals) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString(SessionStore.emailKey);
      if (email == null || email.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy email đăng nhập')),
        );
        return;
      }

      await BackendApi.updateOnboardingProfile(
        email: email,
        goal: updatedGoals,
      );

      if (!mounted) return;
      setState(() {
        _goal = updatedGoals;
      });
      widget.onGoalsUpdated?.call(_goal, _schedule);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã cập nhật mục tiêu')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể cập nhật: $error')));
    }
  }
}

class ProfileTopBar extends StatelessWidget {
  final VoidCallback onSettingsTap;

  const ProfileTopBar({super.key, required this.onSettingsTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Profile',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        GestureDetector(
          onTap: onSettingsTap,
          child: Icon(
            Icons.settings,
            color: Colors.white.withValues(alpha: 0.55),
            size: 23,
          ),
        ),
      ],
    );
  }
}

class ProfileInfoSheet extends StatelessWidget {
  final String title;
  final List<InfoRow> items;
  final List<Widget> actions;

  const ProfileInfoSheet({
    super.key,
    required this.title,
    required this.items,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 22),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: actions
                  .map((action) => Expanded(child: action))
                  .toList(),
            ),
          ],
          const SizedBox(height: 18),
          ...items,
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const InfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 54),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.42),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
