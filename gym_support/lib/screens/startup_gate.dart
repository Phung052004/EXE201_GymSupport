import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gym_support/core/services/backend_api.dart';
import 'package:gym_support/core/services/session_store.dart';
import 'package:gym_support/features/main/screens/main_navigation_screen.dart';

import 'auth_screen.dart';
import 'onboarding_name_screen.dart';

class StartupGate extends StatefulWidget {
  const StartupGate({super.key});

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  late Future<Widget> _routeFuture;

  @override
  void initState() {
    super.initState();
    _routeFuture = _resolveStartScreen();
  }

  Future<Widget> _resolveStartScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(SessionStore.emailKey);
    final token = prefs.getString(SessionStore.tokenKey);
    var userId = prefs.getString(SessionStore.userIdKey);
    final profileComplete =
        prefs.getBool(SessionStore.profileCompleteKey) ?? false;

    if (email == null || email.isEmpty) {
      return const AuthScreen();
    }

    if (!profileComplete && (token == null || token.isEmpty)) {
      return OnboardingNameScreen(email: email);
    }

    try {
      if ((userId == null || userId.isEmpty) &&
          token != null &&
          token.isNotEmpty) {
        userId = await BackendApi.getMeUserId();
        if (userId != null && userId.isNotEmpty) {
          await SessionStore.saveAuth(
            email: email,
            token: token,
            userId: userId,
            profileComplete: profileComplete,
          );
        }
      }

      final profile = await BackendApi.getOnboardingProfileByEmail(email);
      if (!_isProfileComplete(profile)) {
        return OnboardingNameScreen(
          email: email,
          initialName: profile?['name']?.toString(),
        );
      }

      final completeProfile = profile!;
      await SessionStore.saveAuth(
        email: email,
        token: token ?? '',
        userId: userId,
        customerId: completeProfile['id']?.toString(),
        profileComplete: true,
      );

      return MainNavigationScreen(
        name: completeProfile['name']?.toString() ?? email,
        goal: completeProfile['goal']?.toString() ?? '',
        schedule: completeProfile['schedule']?.toString() ?? '',
        bmi: completeProfile['bmi']?.toString() ?? '--',
      );
    } catch (_) {
      if (token != null && token.isNotEmpty) {
        return OnboardingNameScreen(email: email);
      }

      return const AuthScreen();
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
    return FutureBuilder<Widget>(
      future: _routeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const AuthScreen();
        }

        return snapshot.data!;
      },
    );
  }
}
