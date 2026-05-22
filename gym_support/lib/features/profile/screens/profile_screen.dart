import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/session_store.dart';
import 'package:gym_support/features/ai_coach/screens/generate_plan_screen.dart';
import 'package:gym_support/features/ai_coach/screens/scan_equipment_screen.dart';
import '../../../screens/auth_screen.dart';
import '../widgets/logout_button.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_menu_item.dart';
import '../widgets/profile_stat_card.dart';

class ProfileScreen extends StatelessWidget {
  final String name;
  final String goal;
  final String schedule;
  final String bmi;

  const ProfileScreen({
    super.key,
    required this.name,
    required this.goal,
    required this.schedule,
    required this.bmi,
  });

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
          backgroundColor: const Color(0xFF20232B),
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
                await SessionStore.clear();

                Navigator.of(context).pushAndRemoveUntil(
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
            Center(child: ProfileHeader(name: name)),
            const SizedBox(height: 28),
            const Row(
              children: [
                Expanded(
                  child: ProfileStatCard(
                    icon: Icons.emoji_events,
                    iconColor: AppColors.primary,
                    value: '0',
                    label: 'TOTAL WORKOUTS',
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: ProfileStatCard(
                    icon: Icons.flash_on,
                    iconColor: Color(0xFFFF7A30),
                    value: '0h 0m',
                    label: 'TIME TRAINED',
                  ),
                ),
              ],
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
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => GeneratePlanScreen(
                      email: '',
                      name: name,
                      gender: 'Nam',
                      age: '25',
                      weight: '70',
                      height: '175',
                      goal: goal,
                    ),
                  ),
                );
              },
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
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ScanEquipmentScreen(email: ''),
                  ),
                );
              },
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
      backgroundColor: const Color(0xFF20232B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return ProfileInfoSheet(
          title: 'Personal Information',
          items: [
            InfoRow(label: 'Name', value: name),
            InfoRow(label: 'BMI', value: bmi.isEmpty ? '--' : bmi),
          ],
        );
      },
    );
  }

  void showWorkoutPreferencesBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF20232B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return ProfileInfoSheet(
          title: 'Workout Preferences',
          items: [
            InfoRow(label: 'Schedule', value: schedule),
            const InfoRow(label: 'Level', value: 'Beginner'),
          ],
        );
      },
    );
  }

  void showGoalsBottomSheet(BuildContext context) {
    final goals = goal
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF20232B),
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
            const InfoRow(label: 'Weekly Target', value: '3 workouts'),
          ],
        );
      },
    );
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

  const ProfileInfoSheet({super.key, required this.title, required this.items});

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
