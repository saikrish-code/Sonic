import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/ml/sound_labels.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/sonic_colors.dart';
import '../../live_monitor/presentation/widgets/waveform_widget.dart';

/// Debug screen displaying real-time 2D Log-Mel Spectrogram heatmap
/// and class probability distribution across all 20 categories.
class SpectrogramDebugScreen extends ConsumerWidget {
  const SpectrogramDebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioFrameAsync = ref.watch(liveAudioStreamProvider);
    final latestDetection = ref.watch(latestDetectionProvider);

    final frame = audioFrameAsync.asData?.value;
    final spec = frame?.spectrogram ?? [];
    final samples = frame?.samples ?? [];
    final probs = latestDetection?.classProbabilities ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spectrogram & ML Diagnostics'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Spectrogram Heatmap
            const Text(
              'Real-Time Log-Mel Spectrogram (64 Bands)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: SonicColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: SonicColors.surfaceBorder),
              ),
              clipBehavior: Clip.antiAlias,
              child: CustomPaint(
                painter: _SpectrogramHeatmapPainter(spec: spec),
              ),
            ),
            const SizedBox(height: 6),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('50 Hz', style: TextStyle(fontSize: 10, color: SonicColors.textMuted)),
                Text('1 kHz', style: TextStyle(fontSize: 10, color: SonicColors.textMuted)),
                Text('4 kHz', style: TextStyle(fontSize: 10, color: SonicColors.textMuted)),
                Text('8 kHz', style: TextStyle(fontSize: 10, color: SonicColors.textMuted)),
              ],
            ),

            const SizedBox(height: 20),

            // Section 2: Waveform Oscilloscope
            const Text(
              'Input PCM Waveform (16,000 samples)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: SonicColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            WaveformWidget(
              samples: samples,
              height: 70,
              strokeColor: SonicColors.primary,
            ),

            const SizedBox(height: 24),

            // Section 3: Model Probabilities Across 20 Categories
            const Text(
              'General Classifier Confidence Scores (~20 Categories)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: SonicColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: SoundCategories.all.length,
              itemBuilder: (context, index) {
                final cat = SoundCategories.all[index];
                final prob = probs[cat.key] ?? 0.0;
                final isTop = latestDetection?.topCategoryKey == cat.key;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isTop ? cat.color.withAlpha(25) : SonicColors.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isTop ? cat.color.withAlpha(150) : SonicColors.surfaceBorder,
                      width: isTop ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(cat.icon, size: 18, color: isTop ? cat.color : SonicColors.textMuted),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              cat.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isTop ? FontWeight.w800 : FontWeight.w500,
                                color: isTop ? Colors.white : SonicColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            '${(prob * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isTop ? cat.color : SonicColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: prob.clamp(0.0, 1.0),
                          backgroundColor: SonicColors.surfaceLight,
                          color: isTop ? cat.color : SonicColors.primary.withAlpha(120),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SpectrogramHeatmapPainter extends CustomPainter {
  final List<List<double>> spec;

  _SpectrogramHeatmapPainter({required this.spec});

  @override
  void paint(Canvas canvas, Size size) {
    if (spec.isEmpty) return;

    final numFrames = spec.length;
    final numMels = spec.first.length;

    final frameWidth = size.width / numFrames;
    final melHeight = size.height / numMels;

    final paint = Paint()..style = PaintingStyle.fill;

    for (int f = 0; f < numFrames; f++) {
      final frame = spec[f];
      final x = f * frameWidth;

      for (int m = 0; m < numMels; m++) {
        // High frequencies at top, low frequencies at bottom
        final y = size.height - ((m + 1) * melHeight);
        final intensity = frame[m].clamp(0.0, 1.0);

        // Inferno/cyberpunk color grading: dark purple -> magenta -> cyan -> electric yellow
        paint.color = _intensityToColor(intensity);
        canvas.drawRect(Rect.fromLTWH(x, y, frameWidth + 0.5, melHeight + 0.5), paint);
      }
    }
  }

  Color _intensityToColor(double v) {
    if (v < 0.25) {
      final t = v / 0.25;
      return Color.lerp(const Color(0xFF0A0E17), const Color(0xFF431872), t)!;
    } else if (v < 0.6) {
      final t = (v - 0.25) / 0.35;
      return Color.lerp(const Color(0xFF431872), const Color(0xFF00F0FF), t)!;
    } else if (v < 0.85) {
      final t = (v - 0.6) / 0.25;
      return Color.lerp(const Color(0xFF00F0FF), const Color(0xFFFFB703), t)!;
    } else {
      final t = (v - 0.85) / 0.15;
      return Color.lerp(const Color(0xFFFFB703), const Color(0xFFFFFFFF), t)!;
    }
  }

  @override
  bool shouldRepaint(covariant _SpectrogramHeatmapPainter oldDelegate) {
    return oldDelegate.spec != spec;
  }
}
