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
    final profileComplete =
        prefs.getBool(SessionStore.profileCompleteKey) ?? false;

    if (email == null || email.isEmpty) {
      return const AuthScreen();
    }

    if (!profileComplete && (token == null || token.isEmpty)) {
      return OnboardingNameScreen(email: email);
    }

    try {
      final profile = await BackendApi.getOnboardingProfileByEmail(email);
      if (profile == null) {
        return OnboardingNameScreen(email: email);
      }

      await SessionStore.saveAuth(
        email: email,
        token: token ?? '',
        profileComplete: true,
      );

      return MainNavigationScreen(
        name: profile['name']?.toString() ?? email,
        goal: profile['goal']?.toString() ?? '',
        schedule: profile['schedule']?.toString() ?? '',
        bmi: profile['bmi']?.toString() ?? '--',
      );
    } catch (_) {
      if (token != null && token.isNotEmpty) {
        return OnboardingNameScreen(email: email);
      }

      return const AuthScreen();
    }
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
