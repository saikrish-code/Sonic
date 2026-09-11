import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/ml/sound_labels.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/sonic_colors.dart';
import '../../ble_pairing/presentation/pair_device_screen.dart';
import '../../settings/presentation/sound_simulator_screen.dart';
import '../../sound_classifier/presentation/similarity_debug_screen.dart';
import '../../sound_classifier/presentation/spectrogram_debug_screen.dart';
import 'widgets/listening_pulse.dart';
import 'widgets/waveform_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioFrameAsync = ref.watch(liveAudioStreamProvider);
    final isListening = ref.watch(isListeningActiveProvider);
    final latestDetection = ref.watch(latestDetectionProvider);
    final connectedBle = ref.watch(bleConnectedDeviceProvider).asData?.value;

    final samples = audioFrameAsync.asData?.value.samples ?? [];
    final volume = audioFrameAsync.asData?.value.normalizedVolume ?? 0.0;
    final decibels = audioFrameAsync.asData?.value.decibels ?? -80.0;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isListening ? SonicColors.alertGreen : SonicColors.textMuted,
                boxShadow: isListening
                    ? [
                        const BoxShadow(
                          color: SonicColors.alertGreen,
                          blurRadius: 8,
                          spreadRadius: 1,
                        )
                      ]
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            const Text('SONIC'),
          ],
        ),
        actions: [
          // BLE Earpiece Status Badge
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ActionChip(
              avatar: Icon(
                Icons.bluetooth,
                size: 16,
                color: connectedBle?.isConnected == true
                    ? SonicColors.alertGreen
                    : SonicColors.textMuted,
              ),
              label: Text(
                connectedBle?.isConnected == true ? 'Earpiece Active' : 'Pair Wearable',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: connectedBle?.isConnected == true
                      ? SonicColors.alertGreen
                      : SonicColors.textSecondary,
                ),
              ),
              backgroundColor: SonicColors.surfaceLight,
              side: BorderSide(
                color: connectedBle?.isConnected == true
                    ? SonicColors.alertGreen.withAlpha(120)
                    : SonicColors.surfaceBorder,
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PairDeviceScreen()),
                );
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            const SizedBox(height: 8),

            // 1. Radar & Listening Status Hero
            ListeningPulseWidget(
              isListening: isListening,
              volume: volume,
              decibels: decibels,
              onToggleListening: () {
                ref.read(isListeningActiveProvider.notifier).state = !isListening;
              },
            ),

            const SizedBox(height: 16),

            // Listening status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isListening
                    ? SonicColors.alertGreen.withAlpha(30)
                    : SonicColors.surfaceLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isListening
                      ? SonicColors.alertGreen.withAlpha(120)
                      : SonicColors.surfaceBorder,
                ),
              ),
              child: Text(
                isListening ? '● LISTENING FOR CRITICAL SOUNDS' : '⏸ LISTENING PAUSED',
                style: TextStyle(
                  color: isListening ? SonicColors.alertGreen : SonicColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 2. Real-time Waveform Oscilloscope Card
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Live Audio Waveform',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: SonicColors.textSecondary,
                      ),
                    ),
                    Text(
                      '16 kHz Mono',
                      style: TextStyle(
                        fontSize: 12,
                        color: SonicColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                WaveformWidget(
                  samples: samples,
                  height: 64,
                  strokeColor: isListening ? SonicColors.primary : SonicColors.textMuted,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 3. Latest Sound Detection Hero Card
            _LatestDetectionCard(latest: latestDetection),

            const SizedBox(height: 24),

            // 4. Quick Debug & Diagnostic Launchers
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.graphic_eq,
                    label: 'Spectrogram',
                    subtitle: 'Mel Heatmap',
                    color: SonicColors.primary,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SpectrogramDebugScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.radar,
                    label: 'Similarity',
                    subtitle: 'Taught Gauges',
                    color: SonicColors.secondary,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SimilarityDebugScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.play_circle_fill,
                    label: 'Test Lab',
                    subtitle: 'Simulate',
                    color: SonicColors.alertAmber,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SoundSimulatorScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _LatestDetectionCard extends StatelessWidget {
  final dynamic latest;

  const _LatestDetectionCard({required this.latest});

  @override
  Widget build(BuildContext context) {
    if (latest == null || latest.topCategoryKey == 'ambient_silence') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: SonicColors.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: SonicColors.surfaceBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: SonicColors.surfaceLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.hearing,
                color: SonicColors.textMuted,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Environment Quiet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: SonicColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Microphone analyzing rolling 1-second acoustic frames',
                    style: TextStyle(
                      fontSize: 12,
                      color: SonicColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final cat = SoundCategories.getByKey(latest.topCategoryKey);
    final confPercent = (latest.confidence * 100).toInt();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SonicColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cat.color.withAlpha(150), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: cat.color.withAlpha(40),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: cat.color.withAlpha(40),
              shape: BoxShape.circle,
              border: Border.all(color: cat.color, width: 1.5),
            ),
            child: Icon(cat.icon, color: cat.color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      cat.urgency.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: cat.color,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      DateFormat('HH:mm:ss').format(latest.timestamp),
                      style: const TextStyle(
                        fontSize: 11,
                        color: SonicColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  latest.topCategoryLabel,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: latest.confidence.clamp(0.0, 1.0),
                          backgroundColor: SonicColors.surfaceLight,
                          color: cat.color,
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$confPercent%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: cat.color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: SonicColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SonicColors.surfaceBorder),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: SonicColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10,
                color: SonicColors.textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
