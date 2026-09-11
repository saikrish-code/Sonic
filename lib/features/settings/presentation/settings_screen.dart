import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
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
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        children: [
          // Section 1: Navigation shortcuts
          _SettingsActionTile(
            icon: Icons.fingerprint,
            iconColor: SonicColors.primary,
            title: 'Manage Taught Sounds',
            subtitle: 'Rename, adjust sensitivity, or remove custom prototypes',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ManageSoundsScreen()),
              );
            },
          ),
          const SizedBox(height: 10),
          _SettingsActionTile(
            icon: Icons.bluetooth,
            iconColor: SonicColors.alertGreen,
            title: 'Wearable Earpiece (BLE)',
            subtitle: 'Pair future Sonic tactile companion or test mock peripheral',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PairDeviceScreen()),
              );
            },
          ),
          const SizedBox(height: 10),
          _SettingsActionTile(
            icon: Icons.science,
            iconColor: SonicColors.alertAmber,
            title: 'Sound Simulator Lab',
            subtitle: 'Test vibrations, notifications, and 10s debouncing',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SoundSimulatorScreen()),
              );
            },
          ),

          const SizedBox(height: 24),

          // Section 2: Background Listening
          const Text(
            'BACKGROUND LISTENING',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: SonicColors.textMuted,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SonicColors.cardBg,
              borderRadius: BorderRadius.circular(16),
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
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Keep listening for emergency alarms when app is minimized',
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
                      activeColor: SonicColors.primary,
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
                    color: SonicColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: SonicColors.textMuted),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Platform note: Android utilizes a dedicated microphone foreground service. On iOS, continuous background mic capture is restricted by Apple policy when the screen is locked.',
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

          const SizedBox(height: 24),

          // Section 3: Vibration Pattern Tester
          const Text(
            'VIBRATION PATTERN TESTER',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: SonicColors.textMuted,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SonicColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: SonicColors.surfaceBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tap to feel distinct tactile vibrations for each sound priority:',
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
                      color: SonicColors.alertAmber,
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

          const SizedBox(height: 24),

          // Section 4: Per-Category Sensitivity Sliders
          const Text(
            'CATEGORY SENSITIVITY SLIDERS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: SonicColors.textMuted,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SonicColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: SonicColors.surfaceBorder),
            ),
            child: Column(
              children: _categorySensitivities.entries.map((entry) {
                final cat = SoundCategories.getByKey(entry.key);
                final val = entry.value;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(cat.icon, size: 18, color: cat.color),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              cat.label,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: SonicColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            '${(val * 100).toInt()}% Cutoff',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: cat.color,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: val,
                        min: 0.50,
                        max: 0.95,
                        divisions: 18,
                        activeColor: cat.color,
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

          const SizedBox(height: 24),

          // Section 5: Privacy Notice
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SonicColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: SonicColors.surfaceBorder),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock, color: SonicColors.alertGreen, size: 26),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '100% On-Device AI Privacy',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: SonicColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Microphone audio is processed entirely in phone memory via local log-mel spectrograms and quantized models. Raw audio is never uploaded to any cloud server.',
                        style: TextStyle(
                          fontSize: 11,
                          color: SonicColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SonicColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SonicColors.surfaceBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(35),
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
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
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
            const Icon(Icons.chevron_right, color: SonicColors.textMuted),
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
      avatar: Icon(Icons.vibration, size: 16, color: color),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      backgroundColor: color.withAlpha(30),
      side: BorderSide(color: color.withAlpha(120)),
    );
  }
}
