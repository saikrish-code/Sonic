import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/sonic_colors.dart';
import '../../teach_sound/presentation/teach_sound_screen.dart';

/// Live diagnostic screen visualizing real-time Cosine Similarity scores
/// for all user-taught sound prototypes against live microphone embeddings.
class SimilarityDebugScreen extends ConsumerWidget {
  const SimilarityDebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taughtSoundsAsync = ref.watch(allTaughtSoundsProvider);
    final similarityGauges = ref.watch(livePrototypeSimilarityProvider);
    final isListening = ref.watch(isListeningActiveProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Prototype Similarity'),
      ),
      body: taughtSoundsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading prototypes: $err')),
        data: (prototypes) {
          if (prototypes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.hearing_disabled,
                      size: 64,
                      color: SonicColors.textMuted,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No Custom Sounds Taught Yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: SonicColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Teach Sonic your doorbell, microwave beep, or personal alert to see real-time cosine similarity gauges here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: SonicColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const TeachSoundScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Teach a Sound Now'),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: SonicColors.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: SonicColors.surfaceBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isListening ? Icons.graphic_eq : Icons.pause_circle_filled,
                        color: isListening ? SonicColors.primary : SonicColors.textMuted,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isListening
                              ? 'Live cosine similarity calculated every rolling 1s audio window.'
                              : 'Listening paused. Resume on Home screen to see live matching.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: SonicColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Taught Sound Prototypes (128-Dim Embeddings)',
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
                  itemCount: prototypes.length,
                  itemBuilder: (context, index) {
                    final proto = prototypes[index];
                    final rawGauge = similarityGauges[proto.id] ?? 0.0;
                    // Map back to [-1.0, 1.0] similarity for display
                    final simScore = (rawGauge * 2.0) - 1.0;
                    final isMatched = simScore >= proto.threshold;
                    final protoColor = Color(proto.colorValue);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isMatched
                            ? protoColor.withAlpha(30)
                            : SonicColors.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isMatched
                              ? protoColor
                              : SonicColors.surfaceBorder,
                          width: isMatched ? 2.0 : 1.0,
                        ),
                        boxShadow: isMatched
                            ? [
                                BoxShadow(
                                  color: protoColor.withAlpha(60),
                                  blurRadius: 16,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: protoColor.withAlpha(40),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: protoColor, width: 1.5),
                                ),
                                child: Icon(
                                  IconData(proto.iconCode, fontFamily: 'MaterialIcons'),
                                  color: protoColor,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      proto.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${proto.sampleCount} samples • Cutoff: ${(proto.threshold * 100).toInt()}%',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: SonicColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isMatched
                                      ? SonicColors.alertGreen.withAlpha(40)
                                      : SonicColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isMatched
                                        ? SonicColors.alertGreen
                                        : SonicColors.surfaceBorder,
                                  ),
                                ),
                                child: Text(
                                  isMatched ? 'TRIGGERED' : 'AWAITING',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: isMatched
                                        ? SonicColors.alertGreen
                                        : SonicColors.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Cosine Similarity Score',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: SonicColors.textSecondary,
                                ),
                              ),
                              Text(
                                '${(simScore * 100).clamp(0, 100).toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: isMatched ? protoColor : SonicColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: simScore.clamp(0.0, 1.0),
                                  backgroundColor: SonicColors.surfaceLight,
                                  color: isMatched ? protoColor : SonicColors.primary.withAlpha(140),
                                  minHeight: 8,
                                ),
                              ),
                              // Threshold marker indicator
                              Positioned(
                                left: proto.threshold *
                                    (MediaQuery.of(context).size.width - 64),
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  width: 2,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
