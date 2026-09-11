import 'package:flutter/material.dart';
import '../../../../core/theme/sonic_colors.dart';
import 'permissions_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingSlideData> _slides = const [
    _OnboardingSlideData(
      icon: Icons.hearing,
      iconColor: SonicColors.primary,
      title: 'Sound Awareness for Everyone',
      subtitle:
          'Sonic empowers Deaf and hard-of-hearing users with real-time on-device sound detection for doorbells, smoke alarms, sirens, and baby crying.',
    ),
    _OnboardingSlideData(
      icon: Icons.fingerprint,
      iconColor: SonicColors.secondary,
      title: 'Teach Sonic Your World',
      subtitle:
          'Record 2 to 5 short samples of your personal doorbell, microwave ding, or voice. Sonic calculates an acoustic vector to recognize it anywhere.',
    ),
    _OnboardingSlideData(
      icon: Icons.vibration,
      iconColor: SonicColors.alertAmber,
      title: 'Wearable Tactile Alerts',
      subtitle:
          'Feel distinct haptic patterns for danger, urgent alerts, and personal sounds on your phone or paired Bluetooth earpiece companion.',
    ),
  ];

  void _onNext() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _goToPermissions();
    }
  }

  void _goToPermissions() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const PermissionsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              // Top bar: Skip button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _goToPermissions,
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: SonicColors.textMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              // Page View
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (idx) => setState(() => _currentPage = idx),
                  itemBuilder: (context, idx) {
                    final slide = _slides[idx];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: slide.iconColor.withAlpha(30),
                            border: Border.all(
                              color: slide.iconColor.withAlpha(150),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: slide.iconColor.withAlpha(60),
                                blurRadius: 36,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            slide.icon,
                            color: slide.iconColor,
                            size: 64,
                          ),
                        ),
                        const SizedBox(height: 48),
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          slide.subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            color: SonicColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Dots indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (idx) {
                  final isActive = idx == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive ? SonicColors.primary : SonicColors.surfaceLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 36),

              // Bottom Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _onNext,
                  child: Text(
                    _currentPage == _slides.length - 1 ? 'Get Started' : 'Next',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlideData {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _OnboardingSlideData({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });
}
