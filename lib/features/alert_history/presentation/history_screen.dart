import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/database/sonic_database.dart';
import '../../../../core/ml/sound_labels.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/sonic_colors.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertHistoryAsync = ref.watch(alertHistoryProvider);

    return Scaffold(
      backgroundColor: SonicColors.background,
      appBar: AppBar(
        title: const Text(
          'History',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: SonicColors.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: SonicColors.surface,
                  title: const Text('Clear All Alerts?'),
                  content: const Text(
                    'This will erase your past alert logs. This action cannot be undone.',
                    style: TextStyle(color: SonicColors.textSecondary),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SonicColors.alertRed,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                final db = ref.read(databaseProvider);
                await db.clearAlertHistory();
              }
            },
            child: const Text(
              'Clear',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: SonicColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: alertHistoryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: SonicColors.primary)),
        error: (err, _) => Center(child: Text('Error loading history: $err')),
        data: (alerts) {
          if (alerts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: SonicColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.history_toggle_off_rounded,
                        size: 36,
                        color: SonicColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No Alerts Recorded Yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: SonicColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'When sounds or personal audio cues are recognized, they will be logged here with instant feedback controls.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: SonicColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            itemCount: alerts.length,
            itemBuilder: (context, idx) {
              final alert = alerts[idx];
              return _AlertHistoryCard(alert: alert);
            },
          );
        },
      ),
    );
  }
}

class _AlertHistoryCard extends ConsumerWidget {
  final AlertHistoryData alert;

  const _AlertHistoryCard({required this.alert});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(databaseProvider);
    final confPercent = (alert.confidence * 100).toInt();

    // Determine visual style
    Color itemColor = const Color(0xFF8D7AFF);
    IconData itemIcon = Icons.notifications_active_rounded;

    if (alert.isPersonal) {
      itemColor = SonicColors.primary;
      itemIcon = Icons.graphic_eq_rounded;
    } else {
      final matchingCategory = SoundCategories.all.firstWhere(
        (c) => c.label.toLowerCase() == alert.soundName.toLowerCase() ||
            c.key == alert.soundName.toLowerCase(),
        orElse: () => SoundCategories.all.first,
      );
      itemColor = matchingCategory.color;
      itemIcon = matchingCategory.icon;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SonicColors.cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: SonicColors.surfaceBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: itemColor.withAlpha(35),
                  shape: BoxShape.circle,
                  border: Border.all(color: itemColor.withAlpha(120), width: 1.2),
                ),
                child: Icon(itemIcon, color: itemColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: itemColor.withAlpha(30),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            alert.isPersonal ? 'PERSONAL' : alert.category.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: itemColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$confPercent% Match',
                          style: const TextStyle(
                            fontSize: 11,
                            color: SonicColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.soundName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.more_vert_rounded,
                size: 18,
                color: SonicColors.textMuted,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: SonicColors.surfaceBorder, height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 13, color: SonicColors.textMuted),
              const SizedBox(width: 4),
              Text(
                DateFormat('MMM d, h:mm:ss a').format(alert.timestamp),
                style: const TextStyle(fontSize: 11, color: SonicColors.textMuted),
              ),
              const Spacer(),
              const Text(
                'Accurate?',
                style: TextStyle(fontSize: 12, color: SonicColors.textSecondary),
              ),
              const SizedBox(width: 8),

              // Thumbs Up
              InkWell(
                onTap: () async {
                  await db.updateAlertFeedback(alert.id, 1);
                  if (alert.prototypeId != null) {
                    await db.recordThumbsUpForPrototype(alert.prototypeId!);
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Thanks for the feedback!'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: alert.feedback == 1
                        ? SonicColors.alertGreen.withAlpha(35)
                        : SonicColors.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.thumb_up_rounded,
                        size: 14,
                        color: alert.feedback == 1
                            ? SonicColors.alertGreen
                            : SonicColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Yes',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: alert.feedback == 1
                              ? SonicColors.alertGreen
                              : SonicColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Thumbs Down
              InkWell(
                onTap: () async {
                  await db.updateAlertFeedback(alert.id, -1);

                  if (alert.prototypeId != null) {
                    final newThreshold =
                        await db.recordThumbsDownForPrototype(alert.prototypeId!);

                    if (newThreshold != null && context.mounted) {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: SonicColors.surface,
                          title: const Row(
                            children: [
                              Icon(Icons.tune_rounded, color: SonicColors.primaryLight),
                              SizedBox(width: 10),
                              Text('Threshold Adapted'),
                            ],
                          ),
                          content: Text(
                            'Sonic noticed 3 consecutive incorrect detections for "${alert.soundName}".\n\n'
                            'The sensitivity threshold was automatically raised to ${(newThreshold * 100).toStringAsFixed(0)}% to prevent false alarms.',
                            style: const TextStyle(color: SonicColors.textSecondary),
                          ),
                          actions: [
                            ElevatedButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Got it'),
                            ),
                          ],
                        ),
                      );
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Feedback recorded. Sonic is learning!'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: alert.feedback == -1
                        ? SonicColors.alertRed.withAlpha(35)
                        : SonicColors.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.thumb_down_rounded,
                        size: 14,
                        color: alert.feedback == -1
                            ? SonicColors.alertRed
                            : SonicColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'No',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: alert.feedback == -1
                              ? SonicColors.alertRed
                              : SonicColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
