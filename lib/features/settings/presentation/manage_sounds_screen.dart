import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/sonic_database.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/sonic_colors.dart';
import '../../../../core/theme/sonic_icons.dart';
import '../../teach_sound/presentation/teach_sound_screen.dart';

class ManageSoundsScreen extends ConsumerWidget {
  const ManageSoundsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taughtSoundsAsync = ref.watch(allTaughtSoundsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Taught Sounds'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: SonicColors.primary),
            tooltip: 'Teach New Sound',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TeachSoundScreen()),
              );
            },
          ),
        ],
      ),
      body: taughtSoundsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (sounds) {
          if (sounds.isEmpty) {
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
                      'No Custom Sounds Yet',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Teach Sonic your doorbell, alarm, or appliance chime to manage it here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: SonicColors.textSecondary),
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
                      label: const Text('Teach a Sound'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            itemCount: sounds.length,
            itemBuilder: (context, index) {
              final sound = sounds[index];
              return _TaughtSoundItem(sound: sound);
            },
          );
        },
      ),
    );
  }
}

class _TaughtSoundItem extends ConsumerStatefulWidget {
  final TaughtSound sound;

  const _TaughtSoundItem({required this.sound});

  @override
  ConsumerState<_TaughtSoundItem> createState() => _TaughtSoundItemState();
}

class _TaughtSoundItemState extends ConsumerState<_TaughtSoundItem> {
  late double _threshold;

  @override
  void initState() {
    super.initState();
    _threshold = widget.sound.threshold;
  }

  @override
  void didUpdateWidget(covariant _TaughtSoundItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sound.threshold != widget.sound.threshold) {
      _threshold = widget.sound.threshold;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sound = widget.sound;
    final soundColor = Color(sound.colorValue);
    final db = ref.read(databaseProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: soundColor.withAlpha(40),
                  shape: BoxShape.circle,
                  border: Border.all(color: soundColor, width: 1.5),
                ),
                child: Icon(
                  getDynamicIcon(sound.iconCode),
                  color: soundColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sound.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${sound.sampleCount} recorded samples • Consecutive flags: ${sound.consecutiveThumbsDown}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: SonicColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: SonicColors.textSecondary),
                color: SonicColors.surface,
                onSelected: (val) async {
                  if (val == 'rename') {
                    _showRenameDialog(context, sound);
                  } else if (val == 'delete') {
                    _confirmDelete(context, sound);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'rename',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18, color: SonicColors.textPrimary),
                        SizedBox(width: 10),
                        Text('Rename Sound'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: SonicColors.alertRed),
                        SizedBox(width: 10),
                        Text('Delete Sound', style: TextStyle(color: SonicColors.alertRed)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Threshold Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sensitivity Threshold',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: SonicColors.textSecondary,
                ),
              ),
              Text(
                '${(_threshold * 100).toInt()}% Cutoff',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: soundColor,
                ),
              ),
            ],
          ),
          Slider(
            value: _threshold,
            min: AppConstants.minSensitivityThreshold,
            max: AppConstants.maxSensitivityThreshold,
            divisions: 24,
            activeColor: soundColor,
            onChanged: (val) {
              setState(() => _threshold = val);
            },
            onChangeEnd: (val) async {
              await db.updateTaughtSoundThreshold(sound.id, val);
            },
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, TaughtSound sound) {
    final controller = TextEditingController(text: sound.name);
    final db = ref.read(databaseProvider);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SonicColors.surface,
        title: const Text('Rename Sound'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'New sound name',
            filled: true,
            fillColor: SonicColors.cardBg,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await db.updateTaughtSoundDetails(
                  id: sound.id,
                  name: newName,
                  iconCode: sound.iconCode,
                  colorValue: sound.colorValue,
                  threshold: sound.threshold,
                );
              }
              if (context.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, TaughtSound sound) {
    final db = ref.read(databaseProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SonicColors.surface,
        title: Text('Delete "${sound.name}"?'),
        content: const Text(
          'This sound prototype will be permanently removed. Sonic will no longer recognize it.',
          style: TextStyle(color: SonicColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: SonicColors.alertRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await db.deleteTaughtSound(sound.id);
              if (context.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
