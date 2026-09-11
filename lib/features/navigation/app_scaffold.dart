import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    return AlertFlashOverlay(
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: SonicColors.surfaceBorder, width: 1),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (idx) => setState(() => _currentIndex = idx),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.hearing),
                activeIcon: Icon(Icons.hearing, color: SonicColors.primary),
                label: 'Live Monitor',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.school_outlined),
                activeIcon: Icon(Icons.school, color: SonicColors.secondary),
                label: 'Teach Sound',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history),
                activeIcon: Icon(Icons.history, color: SonicColors.alertAmber),
                label: 'Alert History',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings, color: SonicColors.primary),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
