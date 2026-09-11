import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/sonic_colors.dart';
import '../alert_history/presentation/history_screen.dart';
import '../live_monitor/presentation/home_screen.dart';
import '../live_monitor/presentation/widgets/alert_flash_overlay.dart';
import '../settings/presentation/settings_screen.dart';
import '../teach_sound/presentation/teach_sound_screen.dart';

class AppScaffold extends ConsumerStatefulWidget {
  const AppScaffold({super.key});

  @override
  ConsumerState<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends ConsumerState<AppScaffold> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    TeachSoundScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isListening = ref.watch(isListeningActiveProvider);

    return AlertFlashOverlay(
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xE6141026), // 90% opacity deep glass
                borderRadius: BorderRadius.circular(34),
                border: Border.all(
                  color: SonicColors.surfaceBorder,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(120),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: SonicColors.primary.withAlpha(25),
                    blurRadius: 20,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 1. Home
                  _NavItem(
                    icon: Icons.home_filled,
                    label: 'Live Monitor',
                    isActive: _currentIndex == 0,
                    onTap: () => setState(() => _currentIndex = 0),
                  ),

                  // 2. Teach / Sound Library
                  _NavItem(
                    icon: Icons.graphic_eq_rounded,
                    label: 'Teach Sound',
                    isActive: _currentIndex == 1,
                    onTap: () => setState(() => _currentIndex = 1),
                  ),

                  // 3. Center Mic Action Button
                  GestureDetector(
                    onTap: () {
                      ref.read(isListeningActiveProvider.notifier).state = !isListening;
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: isListening
                            ? SonicColors.heroCardGradient
                            : const LinearGradient(
                                colors: [Color(0xFF2B224F), Color(0xFF1B1635)],
                              ),
                        shape: BoxShape.circle,
                        boxShadow: isListening
                            ? [
                                BoxShadow(
                                  color: SonicColors.primary.withAlpha(130),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                        border: Border.all(
                          color: isListening
                              ? const Color(0xFF8D7AFF)
                              : SonicColors.surfaceBorderLight,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        isListening ? Icons.mic_rounded : Icons.mic_off_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),

                  // 4. Alert History
                  _NavItem(
                    icon: Icons.calendar_today_rounded,
                    label: 'Alert History',
                    isActive: _currentIndex == 2,
                    onTap: () => setState(() => _currentIndex = 2),
                  ),

                  // 5. Settings / Grid
                  _NavItem(
                    icon: Icons.grid_view_rounded,
                    label: 'Settings',
                    isActive: _currentIndex == 3,
                    onTap: () => setState(() => _currentIndex = 3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isActive ? SonicColors.surfaceLight : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: isActive ? SonicColors.textPrimary : SonicColors.textMuted,
                ),
              ),
              Positioned.fill(
                child: Center(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 1,
                      color: Colors.transparent,
                    ),
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
