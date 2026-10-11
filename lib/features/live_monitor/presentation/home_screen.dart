import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/ml/live_status.dart';
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
    ref.watch(audioPipelineBootstrapProvider);
    ref.watch(micStateBridgeProvider);
    final audioFrameAsync = ref.watch(liveAudioStreamProvider);
    final isListening = ref.watch(isListeningActiveProvider);
    final liveStatus = ref.watch(liveSoundStatusProvider);
    final connectedBle = ref.watch(bleConnectedDeviceProvider).asData?.value;

    final samples = audioFrameAsync.asData?.value.samples ?? [];
    final decibels = audioFrameAsync.asData?.value.decibels ?? -80.0;
    final displayDecibels = (decibels + 100).clamp(20, 100).toInt();
    final statusDetail = _statusTitle(liveStatus, isListening);

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
                statusDetail,
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
                        _statusPillText(liveStatus, isListening),
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
                            liveStatus.showsEvent
                                ? liveStatus.label
                                : _bentoSubtitle(liveStatus),
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
                                liveStatus.showsEvent
                                    ? '${(liveStatus.confidence * 100).toInt()}%'
                                    : _bentoConfidenceLabel(liveStatus),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: SonicColors.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                liveStatus.showsEvent
                                    ? 'Conf'
                                    : _bentoConfidenceUnit(liveStatus),
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
                          liveStatus.showsEvent
                              ? '${(liveStatus.confidence * 100).toInt()}%'
                              : _heroValue(liveStatus),
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -1.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          liveStatus.showsEvent
                              ? '${liveStatus.label} Detected'
                              : _heroSubtitle(liveStatus),
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

              // 8. Latest Detection Card (single shared live status)
              _LatestDetectionCard(status: liveStatus),

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
  final LiveSoundStatus status;

  const _LatestDetectionCard({required this.status});

  Widget _buildNormalCard(BuildContext context, String title, String subtitle, {IconData icon = Icons.hearing_rounded}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SonicColors.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: SonicColors.surfaceBorder, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: SonicColors.textSecondary,
            size: 26,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: SonicColors.textPrimary,
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (status.kind) {
      case LiveSoundKind.permissionDenied:
        return _buildNormalCard(
          context,
          'Microphone Blocked',
          'Enable microphone access in settings to listen.',
          icon: Icons.mic_off_rounded,
        );
      case LiveSoundKind.microphoneError:
        return _buildNormalCard(
          context,
          'Microphone Error',
          'Audio input unavailable. Check your microphone.',
          icon: Icons.error_outline_rounded,
        );
      case LiveSoundKind.paused:
        return _buildNormalCard(
          context,
          'Paused',
          'Sound monitoring is paused. Tap resume to listen.',
          icon: Icons.pause_rounded,
        );
      case LiveSoundKind.simulationMode:
        return _buildNormalCard(
          context,
          'Demo Mode',
          'Simulated audio. Not real microphone input.',
          icon: Icons.science_rounded,
        );
      case LiveSoundKind.listening:
        return _buildNormalCard(
          context,
          'Listening',
          'Calibrating ambient baseline.',
        );
      case LiveSoundKind.normal:
        return _buildNormalCard(context, 'Normal', 'Ambient level at baseline.');
      case LiveSoundKind.talking:
        return _buildNormalCard(
          context,
          'Talking',
          'Sound level above ambient baseline.',
          icon: Icons.record_voice_over_rounded,
        );
      case LiveSoundKind.event:
        break;
    }

    final cat = status.category ?? SoundCategories.getByKey('danger_explosion');
    final confPercent = (status.confidence * 100).toInt();

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
                      DateFormat('HH:mm:ss').format(DateTime.now()),
                      style: const TextStyle(
                        fontSize: 11,
                        color: SonicColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  status.label,
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
                          value: status.confidence.clamp(0.0, 1.0),
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

String _statusPillText(LiveSoundStatus status, bool isListening) {
  if (!isListening) return 'Listening is paused. Tap to resume.';
  switch (status.kind) {
    case LiveSoundKind.permissionDenied:
      return 'Microphone blocked. Enable access in settings.';
    case LiveSoundKind.microphoneError:
      return 'Microphone error. Check your audio input.';
    case LiveSoundKind.simulationMode:
      return 'Demo mode: simulated audio, not the microphone.';
    case LiveSoundKind.event:
      return 'Event detected: ${status.label}.';
    case LiveSoundKind.talking:
      return 'Elevated sound level detected.';
    case LiveSoundKind.paused:
      return 'Listening is paused. Tap to resume.';
    case LiveSoundKind.listening:
      return 'Calibrating ambient baseline.';
    case LiveSoundKind.normal:
      return 'Continuous acoustic monitoring active.';
  }
}

String _statusTitle(LiveSoundStatus status, bool isListening) {
  if (!isListening) return 'Sound monitoring\nis paused';
  switch (status.kind) {
    case LiveSoundKind.event:
      return 'Sound detected:\n${status.label}';
    case LiveSoundKind.talking:
      return 'Elevated sound\nlevel detected';
    case LiveSoundKind.permissionDenied:
      return 'Microphone\nis blocked';
    case LiveSoundKind.microphoneError:
      return 'Microphone\nerror';
    case LiveSoundKind.paused:
      return 'Sound monitoring\nis paused';
    case LiveSoundKind.simulationMode:
      return 'Demo mode:\nsimulated audio';
    case LiveSoundKind.listening:
      return 'Listening to your\nenvironment';
    case LiveSoundKind.normal:
      return 'Listening to your\nenvironment';
  }
}

String _bentoSubtitle(LiveSoundStatus status) {
  switch (status.kind) {
    case LiveSoundKind.event:
      return status.label;
    case LiveSoundKind.talking:
      return 'above baseline';
    case LiveSoundKind.permissionDenied:
      return 'permission denied';
    case LiveSoundKind.microphoneError:
      return 'mic error';
    case LiveSoundKind.paused:
      return 'paused';
    case LiveSoundKind.simulationMode:
      return 'simulated audio';
    case LiveSoundKind.listening:
      return 'calibrating';
    case LiveSoundKind.normal:
      return 'quiet ambient';
  }
}

String _bentoConfidenceLabel(LiveSoundStatus status) {
  switch (status.kind) {
    case LiveSoundKind.event:
      return '${(status.confidence * 100).toInt()}%';
    case LiveSoundKind.talking:
      return 'Talking';
    case LiveSoundKind.permissionDenied:
      return 'Blocked';
    case LiveSoundKind.microphoneError:
      return 'Error';
    case LiveSoundKind.paused:
      return 'Off';
    case LiveSoundKind.simulationMode:
      return 'Demo';
    case LiveSoundKind.listening:
      return 'Live';
    case LiveSoundKind.normal:
      return 'Safe';
  }
}

String _bentoConfidenceUnit(LiveSoundStatus status) {
  switch (status.kind) {
    case LiveSoundKind.event:
      return 'Conf';
    case LiveSoundKind.talking:
      return 'Level';
    default:
      return 'Acoustic';
  }
}

String _heroValue(LiveSoundStatus status) {
  switch (status.kind) {
    case LiveSoundKind.event:
      return '${(status.confidence * 100).toInt()}%';
    case LiveSoundKind.talking:
      return 'Talking';
    case LiveSoundKind.permissionDenied:
      return 'Blocked';
    case LiveSoundKind.microphoneError:
      return 'Error';
    case LiveSoundKind.paused:
      return 'Off';
    case LiveSoundKind.simulationMode:
      return 'Demo';
    case LiveSoundKind.listening:
      return 'Live';
    case LiveSoundKind.normal:
      return 'Normal';
  }
}

String _heroSubtitle(LiveSoundStatus status) {
  switch (status.kind) {
    case LiveSoundKind.event:
      return '${status.label} Detected';
    case LiveSoundKind.talking:
      return 'Above Baseline';
    case LiveSoundKind.permissionDenied:
      return 'Enable Microphone';
    case LiveSoundKind.microphoneError:
      return 'Check Microphone';
    case LiveSoundKind.paused:
      return 'Monitoring Paused';
    case LiveSoundKind.simulationMode:
      return 'Simulated Audio';
    case LiveSoundKind.listening:
      return 'Calibrating Baseline';
    case LiveSoundKind.normal:
      return 'At Baseline';
  }
}
