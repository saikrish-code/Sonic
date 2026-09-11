import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/ml/sound_labels.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/sonic_colors.dart';
import '../../../../core/theme/sonic_icons.dart';

/// Interactive testing lab allowing immediate simulation of sounds to verify
/// vibration patterns, notifications, in-app visual alert strobes, and 10s debouncing.
class SoundSimulatorScreen extends ConsumerWidget {
  const SoundSimulatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taughtSoundsAsync = ref.watch(allTaughtSoundsProvider);
    final alertService = ref.read(alertServiceProvider);
    final audioService = ref.read(audioRecorderServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sound Simulator & Lab'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: SonicColors.primary),
            tooltip: 'Clear 10s Debounce Cooldown',
            onPressed: () {
              alertService.clearDebounceHistory();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Debounce cooldowns reset. Sounds can trigger immediately.'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: SonicColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: SonicColors.surfaceBorder),
              ),
              child: const Row(
                children: [
                  Icon(Icons.science, color: SonicColors.alertAmber, size: 28),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Tap any sound below to simulate its acoustic trigger. This tests vibration patterns, notifications, screen flashes, and 10-second debouncing.',
                      style: TextStyle(
                        fontSize: 13,
                        color: SonicColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section 1: General Category Simulators
            const Text(
              'General Categories (~20 Sounds)',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: SonicColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.2,
              ),
              itemCount: SoundCategories.all.length,
              itemBuilder: (context, index) {
                final cat = SoundCategories.all[index];
                final isDebounced = alertService.isDebounced(cat.key);

                return InkWell(
                  onTap: () async {
                    // Inject synthetic acoustic tone
                    audioService.injectSyntheticSound(
                      frequencyHz: 1200.0,
                      amplitude: 0.8,
                      duration: const Duration(milliseconds: 600),
                    );

                    final triggered = await alertService.triggerAlert(
                      soundKey: cat.key,
                      soundName: cat.label,
                      category: cat.urgency.name.toUpperCase(),
                      confidence: 0.94,
                      isPersonal: false,
                      color: cat.color,
                      icon: cat.icon,
                    );

                    if (!triggered && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('"${cat.label}" is within 10s cooldown. Debounced!'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: SonicColors.cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDebounced
                            ? SonicColors.surfaceBorder
                            : cat.color.withAlpha(120),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: cat.color.withAlpha(35),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(cat.icon, color: cat.color, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                cat.label,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                isDebounced ? 'Cooldown' : 'Ready',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDebounced
                                      ? SonicColors.textMuted
                                      : SonicColors.alertGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 28),

            // Section 2: Custom Taught Sounds
            const Text(
              'Your Taught Sound Prototypes',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: SonicColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            taughtSoundsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox(),
              data: (prototypes) {
                if (prototypes.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: SonicColors.cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: SonicColors.surfaceBorder),
                    ),
                    child: const Center(
                      child: Text(
                        'No custom sounds taught yet. Teach one via the "Teach" tab!',
                        style: TextStyle(color: SonicColors.textMuted, fontSize: 13),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: prototypes.length,
                  itemBuilder: (context, idx) {
                    final proto = prototypes[idx];
                    final color = Color(proto.colorValue);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: SonicColors.surfaceBorder),
                        ),
                        tileColor: SonicColors.cardBg,
                        leading: CircleAvatar(
                          backgroundColor: color.withAlpha(40),
                          child: Icon(
                            getDynamicIcon(proto.iconCode),
                            color: color,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          proto.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          'Cutoff: ${(proto.threshold * 100).toInt()}%',
                          style: const TextStyle(fontSize: 12, color: SonicColors.textMuted),
                        ),
                        trailing: ElevatedButton.icon(
                          onPressed: () async {
                            final triggered = await alertService.triggerAlert(
                              soundKey: proto.id,
                              soundName: proto.name,
                              category: 'PERSONAL',
                              confidence: 0.96,
                              isPersonal: true,
                              prototypeId: proto.id,
                              color: color,
                              icon: getDynamicIcon(proto.iconCode),
                            );

                            if (!triggered && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('"${proto.name}" is within 10s cooldown.'),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.play_arrow, size: 16),
                          label: const Text('Simulate'),
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
