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
      appBar: AppBar(
        title: const Text('Alert History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: SonicColors.textMuted),
            tooltip: 'Clear history',
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
          ),
        ],
      ),
      body: alertHistoryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
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
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: SonicColors.surfaceLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.history_toggle_off,
                        size: 40,
                        color: SonicColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No Alerts Recorded Yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: SonicColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'When Sonic detects general alarms or your personal taught sounds, they will be logged here with instant feedback controls.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            physics: const BouncingScrollPhysics(),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index];
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
    Color itemColor = SonicColors.alertAmber;
    IconData itemIcon = Icons.notifications_active;

    if (alert.isPersonal) {
      itemColor = SonicColors.primary;
      itemIcon = Icons.fingerprint;
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SonicColors.surfaceBorder),
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
                  color: itemColor.withAlpha(40),
                  shape: BoxShape.circle,
                  border: Border.all(color: itemColor, width: 1.5),
                ),
                child: Icon(itemIcon, color: itemColor, size: 22),
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
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: itemColor.withAlpha(40),
                            borderRadius: BorderRadius.circular(4),
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
                          '$confPercent% Confidence',
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
              Text(
                DateFormat('h:mm a').format(alert.timestamp),
                style: const TextStyle(
                  fontSize: 12,
                  color: SonicColors.textMuted,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(color: SonicColors.surfaceBorder, height: 1),
          const SizedBox(height: 10),

          // Feedback Controls (Thumbs Up / Down)
          Row(
            children: [
              Text(
                DateFormat.yMMMd().format(alert.timestamp),
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
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: alert.feedback == 1
                        ? SonicColors.alertGreen.withAlpha(40)
                        : SonicColors.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: alert.feedback == 1
                          ? SonicColors.alertGreen
                          : SonicColors.surfaceBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.thumb_up,
                        size: 15,
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
                    // Check if 3 consecutive thumbs-down triggered automatic threshold elevation
                    final newThreshold =
                        await db.recordThumbsDownForPrototype(alert.prototypeId!);

                    if (newThreshold != null && context.mounted) {
                      // Show prominent threshold adaptation banner to user
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: SonicColors.surface,
                          title: const Row(
                            children: [
                              Icon(Icons.tune, color: SonicColors.alertAmber),
                              SizedBox(width: 10),
                              Text('Threshold Adjusted'),
                            ],
                          ),
                          content: Text(
                            'Sonic noticed 3 consecutive thumbs-down reports on "${alert.soundName}".\n\nTo prevent false alarms, Sonic has automatically raised the similarity threshold for "${alert.soundName}" to ${(newThreshold * 100).toInt()}%.',
                            style: const TextStyle(color: SonicColors.textSecondary),
                          ),
                          actions: [
                            ElevatedButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Got It'),
                            ),
                          ],
                        ),
                      );
                    }
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: alert.feedback == -1
                        ? SonicColors.alertRed.withAlpha(40)
                        : SonicColors.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: alert.feedback == -1
                          ? SonicColors.alertRed
                          : SonicColors.surfaceBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.thumb_down,
                        size: 15,
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
