import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/ml/sound_labels.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/sonic_colors.dart';
import '../../ble_pairing/presentation/pair_device_screen.dart';
import 'manage_sounds_screen.dart';
import 'sound_simulator_screen.dart';

final backgroundListeningProvider = StateProvider<bool>((ref) => true);

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Local sensitivity sliders state
  final Map<String, double> _categorySensitivities = {
    'smoke_alarm': 0.65,
    'doorbell': 0.70,
    'baby_crying': 0.72,
    'door_knock': 0.70,
    'siren': 0.70,
    'dog_bark': 0.72,
  };

  @override
  Widget build(BuildContext context) {
    final isBackgroundActive = ref.watch(backgroundListeningProvider);
    final vibService = ref.read(vibrationServiceProvider);

    return Scaffold(
      backgroundColor: SonicColors.background,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: SonicColors.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        physics: const BouncingScrollPhysics(),
        children: [
          // Section 1: Navigation shortcuts
          _SettingsActionTile(
            icon: Icons.fingerprint_rounded,
            iconColor: SonicColors.primaryLight,
            title: 'Manage Taught Sounds',
            subtitle: 'Rename, adjust sensitivity, or remove custom prototypes',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ManageSoundsScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          _SettingsActionTile(
            icon: Icons.bluetooth_rounded,
            iconColor: const Color(0xFF8D7AFF),
            title: 'Wearable Earpiece (BLE)',
            subtitle: 'Pair future tactile companion or simulate earpiece',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PairDeviceScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          _SettingsActionTile(
            icon: Icons.science_outlined,
            iconColor: SonicColors.secondary,
            title: 'Sound Simulator Lab',
            subtitle: 'Test vibrations, notifications, and 10s debouncing',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SoundSimulatorScreen()),
              );
            },
          ),

          const SizedBox(height: 28),

          // Section 2: Background Listening
          const Text(
            'BACKGROUND LISTENING',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: SonicColors.textMuted,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: SonicColors.cardBg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: SonicColors.surfaceBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Continuous Background Listening',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Keep listening for vital sounds when app is minimized',
                            style: TextStyle(
                              fontSize: 12,
                              color: SonicColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isBackgroundActive,
                      activeThumbColor: Colors.white,
                      activeTrackColor: SonicColors.primary,
                      inactiveTrackColor: SonicColors.surfaceLight,
                      onChanged: (val) {
                        ref.read(backgroundListeningProvider.notifier).state = val;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: SonicColors.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 18, color: SonicColors.textMuted),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Platform note: Android utilizes a dedicated microphone foreground service. On iOS, background microphone access follows iOS privacy guidelines.',
                          style: TextStyle(
                            fontSize: 11,
                            color: SonicColors.textMuted,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Section 3: Vibration Pattern Tester
          const Text(
            'VIBRATION PATTERN TESTER',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: SonicColors.textMuted,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: SonicColors.cardBg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: SonicColors.surfaceBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tap to feel distinct tactile vibrations for each category:',
                  style: TextStyle(fontSize: 13, color: SonicColors.textSecondary),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _VibrationTestChip(
                      label: 'Danger (Smoke/Fire)',
                      color: SonicColors.alertRed,
                      onTap: () => vibService.triggerVibrationForCategory('smoke_alarm'),
                    ),
                    _VibrationTestChip(
                      label: 'Urgent (Baby/Glass)',
                      color: const Color(0xFFFF6B6B),
                      onTap: () => vibService.triggerVibrationForCategory('baby_crying'),
                    ),
                    _VibrationTestChip(
                      label: 'Doorbell (3 Pulses)',
                      color: SonicColors.primaryLight,
                      onTap: () => vibService.triggerVibrationForCategory('doorbell'),
                    ),
                    _VibrationTestChip(
                      label: 'Personal Taught Sound',
                      color: SonicColors.primary,
                      onTap: () => vibService.triggerPersonalSoundVibration(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Section 4: Per-Category Sensitivity Sliders
          const Text(
            'CATEGORY SENSITIVITY THRESHOLDS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: SonicColors.textMuted,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: SonicColors.cardBg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: SonicColors.surfaceBorder),
            ),
            child: Column(
              children: _categorySensitivities.entries.map((entry) {
                final category = SoundCategories.getByKey(entry.key);
                final currentVal = entry.value;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(category.icon, size: 16, color: category.color),
                              const SizedBox(width: 8),
                              Text(
                                category.label,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${(currentVal * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: SonicColors.primaryLight,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: currentVal,
                        min: 0.50,
                        max: 0.95,
                        divisions: 9,
                        onChanged: (newVal) {
                          setState(() {
                            _categorySensitivities[entry.key] = newVal;
                          });
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: SonicColors.cardBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: SonicColors.surfaceBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: SonicColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: SonicColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _VibrationTestChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _VibrationTestChip({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      avatar: Icon(Icons.vibration_rounded, size: 14, color: color),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: SonicColors.textPrimary,
        ),
      ),
      backgroundColor: SonicColors.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: SonicColors.surfaceBorder),
      ),
    );
  }
}
