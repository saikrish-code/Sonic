import 'package:flutter/material.dart';
import 'core/theme/sonic_theme.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';

class SonicApp extends StatelessWidget {
  const SonicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sonic',
      debugShowCheckedModeBanner: false,
      theme: SonicTheme.darkTheme,
      home: const OnboardingScreen(),
    );
  }
}
