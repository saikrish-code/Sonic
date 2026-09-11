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
    final decibels = audioFrameAsync.asData?.value.decibels ?? -80.0;
    final displayDecibels = (decibels + 100).clamp(20, 100).toInt();

    return Scaffold(
      backgroundColor: SonicColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Header Bar (Matching Aura capsule design with real Sonic features)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Wearable / BLE pill button
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PairDeviceScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: SonicColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: SonicColors.surfaceBorderLight, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bluetooth_rounded,
                            size: 14,
                            color: connectedBle?.isConnected == true
                                ? SonicColors.alertGreen
                                : SonicColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            connectedBle?.isConnected == true ? 'Connected' : 'Wearable',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: connectedBle?.isConnected == true
                                  ? SonicColors.alertGreen
                                  : SonicColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Center Pill Badge: "Sonic 1.0 LIVE"
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: SonicColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: SonicColors.surfaceBorderLight, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Sonic 1.0 ',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: SonicColors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isListening ? const Color(0x3300F0FF) : SonicColors.surfaceLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isListening ? 'LIVE' : 'OFF',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: isListening ? const Color(0xFF00F0FF) : SonicColors.textMuted,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Quick Mic Toggle button
                  IconButton(
                    icon: Icon(
                      isListening ? Icons.mic_rounded : Icons.mic_off_rounded,
                      color: isListening ? SonicColors.primaryLight : SonicColors.textMuted,
                      size: 24,
                    ),
                    onPressed: () {
                      ref.read(isListeningActiveProvider.notifier).state = !isListening;
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 2. Greeting & Title in clean minimalist typography
              const Text(
                'Acoustic Space',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: SonicColors.textSecondary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isListening ? "Listening to your\nenvironment" : "Sound monitoring\nis paused",
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: SonicColors.textPrimary,
                  height: 1.18,
                  letterSpacing: -0.8,
                ),
              ),

              const SizedBox(height: 22),

              // 3. Live Ambient Audio Status Pill
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: SonicColors.surface,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: SonicColors.surfaceBorder, width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isListening ? const Color(0xFF00F0FF) : SonicColors.textMuted,
                        boxShadow: isListening
                            ? [
                                const BoxShadow(
                                  color: Color(0xFF00F0FF),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isListening
                            ? 'Continuous acoustic monitoring active'
                            : 'Listening is paused. Tap to resume.',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: SonicColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        ref.read(isListeningActiveProvider.notifier).state = !isListening;
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: SonicColors.surfaceLight,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isListening ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: SonicColors.textPrimary,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // 4. Horizontal Quick Action Pills (Real Sonic features)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _ActionPill(
                      icon: Icons.graphic_eq_rounded,
                      label: 'Spectrogram',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SpectrogramDebugScreen()),
                        );
                      },
                    ),
                    const SizedBox(width: 10),
                    _ActionPill(
                      icon: Icons.radar_rounded,
                      label: 'Similarity',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SimilarityDebugScreen()),
                        );
                      },
                    ),
                    const SizedBox(width: 10),
                    _ActionPill(
                      icon: Icons.science_rounded,
                      label: 'Sound Lab',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SoundSimulatorScreen()),
                        );
                      },
                    ),
                    const SizedBox(width: 10),
                    _ActionPill(
                      icon: Icons.headphones_rounded,
                      label: 'Pair Wearable',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PairDeviceScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // 5. Section Header
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Live Telemetry',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: SonicColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: SonicColors.textSecondary,
                    size: 22,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // 6. Dual Bento Cards (Live Audio Waveform & Sound Status)
              Row(
                children: [
                  // Left Bento Card: Waveform & Decibels
                  Expanded(
                    child: Container(
                      height: 190,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: SonicColors.cardBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: SonicColors.surfaceBorder, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Audio level',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: SonicColors.textPrimary,
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded, size: 18, color: SonicColors.textSecondary),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'live mic',
                            style: TextStyle(
                              fontSize: 12,
                              color: SonicColors.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          // Purple Neon Waveform line
                          SizedBox(
                            height: 48,
                            child: WaveformWidget(
                              samples: samples,
                              height: 48,
                              strokeColor: const Color(0xFF8D7AFF),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '$displayDecibels',
                                style: const TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w700,
                                  color: SonicColors.textPrimary,
                                  letterSpacing: -1.0,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'dB',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: SonicColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Right Bento Card: Sound Detection Status
                  Expanded(
                    child: Container(
                      height: 190,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: SonicColors.cardBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: SonicColors.surfaceBorder, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Sound State',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: SonicColors.textPrimary,
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded, size: 18, color: SonicColors.textSecondary),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            latestDetection != null && latestDetection.topCategoryKey != 'ambient_silence'
                                ? latestDetection.topCategoryLabel
                                : 'quiet ambient',
                            style: const TextStyle(
                              fontSize: 12,
                              color: SonicColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          // Glowing Purple Horizon Curve
                          Container(
                            height: 44,
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xAA7A4BFF), Color(0x00141126)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(30),
                                topRight: Radius.circular(30),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                latestDetection != null && latestDetection.topCategoryKey != 'ambient_silence'
                                    ? '${(latestDetection.confidence * 100).toInt()}%'
                                    : 'Safe',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: SonicColors.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                latestDetection != null && latestDetection.topCategoryKey != 'ambient_silence'
                                    ? 'Conf'
                                    : 'Acoustic',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: SonicColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 7. Signature Electric Violet Hero Tile (Sound Shield & Test Compatibility)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: SonicColors.heroCardGradient,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: SonicColors.primary.withAlpha(90),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Sound Shield',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 20),
                              ],
                            ),
                            SizedBox(height: 2),
                            Text(
                              'On-Device ML Classifier',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        // Test pass token
                        Text(
                          isListening ? '● LISTENING FOR CRITICAL SOUNDS' : '⏸ LISTENING PAUSED',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 26),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          latestDetection != null && latestDetection.topCategoryKey != 'ambient_silence'
                              ? '${(latestDetection.confidence * 100).toInt()}%'
                              : '20',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -1.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          latestDetection != null && latestDetection.topCategoryKey != 'ambient_silence'
                              ? '${latestDetection.topCategoryLabel} Detected'
                              : 'Hazard Categories Active',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 8. Latest Detection Card (When sound is detected or quiet)
              _LatestDetectionCard(latest: latestDetection),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: SonicColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: SonicColors.surfaceBorder, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: SonicColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: SonicColors.textPrimary,
              ),
            ),
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
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: SonicColors.surfaceBorder, width: 1),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.hearing_rounded,
              color: SonicColors.textSecondary,
              size: 26,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Environment Quiet',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: SonicColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cat.color.withAlpha(160), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: cat.color.withAlpha(50),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: cat.color.withAlpha(40),
              shape: BoxShape.circle,
              border: Border.all(color: cat.color, width: 1.5),
            ),
            child: Icon(cat.icon, color: cat.color, size: 24),
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
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: latest.confidence.clamp(0.0, 1.0),
                          backgroundColor: SonicColors.surfaceLight,
                          color: cat.color,
                          minHeight: 5,
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
