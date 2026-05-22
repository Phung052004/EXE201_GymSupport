import 'package:flutter/material.dart';
import 'screens/startup_gate.dart';

void main() {
  runApp(const GymSupportApp());
}

class GymSupportApp extends StatelessWidget {
  const GymSupportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GymSupport AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFF171A21),
        useMaterial3: true,
      ),
      home: const StartupGate(),
    );
  }
}
