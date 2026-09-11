import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/audio/mel_spectrogram.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/sonic_database.dart';
import '../../../../core/ml/embedding_engine.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/sonic_colors.dart';

class TeachSoundScreen extends ConsumerStatefulWidget {
  const TeachSoundScreen({super.key});

  @override
  ConsumerState<TeachSoundScreen> createState() => _TeachSoundScreenState();
}

class _TeachSoundScreenState extends ConsumerState<TeachSoundScreen> {
  final TextEditingController _nameController = TextEditingController(text: 'My Doorbell');
  int _selectedIconCode = Icons.doorbell.codePoint;
  int _selectedColorValue = 0xFF5E45FF;

  // Recorded samples storage: each sample is a List<double> of audio PCM samples
  final List<List<double>> _recordedSamples = [];

  bool _isRecordingSample = false;
  int _recordingCountdown = 3;
  Timer? _countdownTimer;
  int _activeSampleTab = 0;

  static const List<IconData> _availableIcons = [
    Icons.doorbell_rounded,
    Icons.notifications_active_rounded,
    Icons.alarm_rounded,
    Icons.pets_rounded,
    Icons.child_care_rounded,
    Icons.phone_in_talk_rounded,
    Icons.volume_up_rounded,
    Icons.microwave_rounded,
  ];

  static const List<Color> _availableColors = [
    Color(0xFF5E45FF), // Electric Violet
    Color(0xFF8D7AFF), // Lavender Glow
    Color(0xFF00F0FF), // Cyber Cyan
    Color(0xFFFF007F), // Neon Pink
    Color(0xFFFFB703), // Amber
    Color(0xFF00E676), // Bright Green
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _startRecordingSample() async {
    if (_isRecordingSample) return;
    if (_recordedSamples.length >= AppConstants.maxSamplesToTeach) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 samples reached.')),
      );
      return;
    }

    setState(() {
      _isRecordingSample = true;
      _recordingCountdown = 3;
    });

    final audioService = ref.read(audioRecorderServiceProvider);
    final recordedPcmFuture = audioService.recordSampleForTeaching(durationSeconds: 3);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_recordingCountdown > 1) {
        if (mounted) setState(() => _recordingCountdown--);
      } else {
        t.cancel();
      }
    });

    try {
      final sample = await recordedPcmFuture;
      if (mounted) {
        setState(() {
          _recordedSamples.add(sample);
          _isRecordingSample = false;
          _activeSampleTab = _recordedSamples.length - 1;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sample ${_recordedSamples.length} recorded successfully!'),
            backgroundColor: SonicColors.surfaceLight,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRecordingSample = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recording error: $e')),
        );
      }
    }
  }

  Future<void> _savePrototype() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name for your sound.')),
      );
      return;
    }

    if (_recordedSamples.length < AppConstants.minSamplesToTeach) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please record at least ${AppConstants.minSamplesToTeach} samples.'),
        ),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: SonicColors.primary),
      ),
    );

    try {
      final classifier = ref.read(soundClassifierProvider);

      // Extract embedding for each sample
      final specExtractor = MelSpectrogramExtractor();
      final sampleEmbeddings = <List<double>>[];
      for (final sample in _recordedSamples) {
        final spec = specExtractor.extract(sample);
        final result = classifier.classify(spec);
        sampleEmbeddings.add(result.embedding);
      }

      // Average vectors and L2 normalize
      final prototypeVector = EmbeddingEngine.averagePrototypes(sampleEmbeddings);

      // Save to Drift database
      final db = ref.read(databaseProvider);
      final prototype = TaughtSound(
        id: const Uuid().v4(),
        name: name,
        iconCode: _selectedIconCode,
        colorValue: _selectedColorValue,
        embeddingJson: jsonEncode(prototypeVector),
        sampleCount: _recordedSamples.length,
        threshold: AppConstants.defaultSimilarityThreshold,
        consecutiveThumbsDown: 0,
        createdAt: DateTime.now(),
        isEnabled: true,
      );

      await db.insertTaughtSound(prototype);

      if (mounted) {
        Navigator.of(context).pop(); // Pop loading

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sound "$name" successfully taught and saved!'),
            backgroundColor: SonicColors.surfaceLight,
          ),
        );

        // Reset state
        setState(() {
          _nameController.clear();
          _recordedSamples.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save sound: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SonicColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: SonicColors.textPrimary, size: 24),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: SonicColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: SonicColors.surfaceBorderLight, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.graphic_eq_rounded, size: 14, color: SonicColors.primaryLight),
                        const SizedBox(width: 6),
                        Text(
                          '${_recordedSamples.length}/5 Samples',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: SonicColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Editorial Two-Line Title
              const Text(
                'Teach Sound\nprototype',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: SonicColors.textPrimary,
                  height: 1.15,
                  letterSpacing: -0.8,
                ),
              ),

              const SizedBox(height: 20),

              // Sample Slot Pills: [ 1 ] [ 2 ] [ 3 ] [ 4 ] [ 5 ]
              Row(
                children: [
                  for (int i = 0; i < 5; i++) ...[
                    _SampleSlotPill(
                      index: i + 1,
                      isRecorded: i < _recordedSamples.length,
                      isSelected: _activeSampleTab == i,
                      onTap: () => setState(() => _activeSampleTab = i),
                    ),
                    if (i < 4) const SizedBox(width: 8),
                  ],
                  const Spacer(),
                  const Icon(Icons.mic_none_rounded, color: SonicColors.textSecondary, size: 22),
                ],
              ),

              const SizedBox(height: 22),

              // Bento Grid: Left Hero Electric Violet Card + Right Column Cards
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Electric Violet Card (Tap to record)
                  Expanded(
                    flex: 11,
                    child: GestureDetector(
                      onTap: _startRecordingSample,
                      child: Container(
                        height: 210,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: SonicColors.heroCardGradient,
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: SonicColors.primary.withAlpha(90),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Text(
                                  'Audio Capture',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 18),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isRecordingSample
                                  ? 'Recording (${_recordingCountdown}s)...'
                                  : 'Tap to Record Sample',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                              ),
                            ),
                            const Spacer(),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  _isRecordingSample ? '0$_recordingCountdown' : '${_recordedSamples.length}',
                                  style: const TextStyle(
                                    fontSize: 44,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -1.0,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _isRecordingSample ? 'Sec' : '/ 5 Samples',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Right Column Cards
                  Expanded(
                    flex: 9,
                    child: Column(
                      children: [
                        // Card 1: Sensitivity Threshold
                        Container(
                          height: 98,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: SonicColors.cardBg,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: SonicColors.surfaceBorder, width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Sensitivity',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: SonicColors.textPrimary,
                                    ),
                                  ),
                                  Icon(Icons.chevron_right_rounded, size: 16, color: SonicColors.textSecondary),
                                ],
                              ),
                              const Spacer(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    '85%',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: SonicColors.textSecondary,
                                    ),
                                  ),
                                  Container(
                                    width: 44,
                                    height: 24,
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Color(0xCC7A4BFF), Color(0x00141126)],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(16),
                                        topRight: Radius.circular(16),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Card 2: ML Engine / Few-Shot
                        Container(
                          height: 98,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: SonicColors.cardBg,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: SonicColors.surfaceBorder, width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Engine',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: SonicColors.textPrimary,
                                    ),
                                  ),
                                  Icon(Icons.chevron_right_rounded, size: 16, color: SonicColors.textSecondary),
                                ],
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: SonicColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: SonicColors.surfaceBorderLight, width: 1),
                                ),
                                child: const Text(
                                  'Few-Shot ML',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: SonicColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Sound Name Config Card (retains "1. Name Your Sound" for test compatibility)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: SonicColors.cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: SonicColors.surfaceBorder, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '1. Name Your Sound',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: SonicColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: SonicColors.textPrimary, fontSize: 16),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: SonicColors.surface,
                        hintText: 'e.g. My Doorbell, Baby Cry...',
                        hintStyle: const TextStyle(color: SonicColors.textMuted),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Icon and color picker row
                    Row(
                      children: [
                        const Text(
                          'Icon & Accent',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: SonicColors.textMuted,
                          ),
                        ),
                        const Spacer(),
                        for (final icon in _availableIcons.take(4))
                          GestureDetector(
                            onTap: () => setState(() => _selectedIconCode = icon.codePoint),
                            child: Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _selectedIconCode == icon.codePoint
                                    ? SonicColors.primaryLight.withAlpha(50)
                                    : SonicColors.surface,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _selectedIconCode == icon.codePoint
                                      ? SonicColors.primaryLight
                                      : Colors.transparent,
                                ),
                              ),
                              child: Icon(
                                icon,
                                size: 16,
                                color: _selectedIconCode == icon.codePoint
                                    ? SonicColors.textPrimary
                                    : SonicColors.textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text(
                          'Accent Color',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: SonicColors.textMuted,
                          ),
                        ),
                        const Spacer(),
                        for (final color in _availableColors.take(5))
                          GestureDetector(
                            onTap: () => setState(() => _selectedColorValue = color.toARGB32()),
                            child: Container(
                              margin: const EdgeInsets.only(left: 8),
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _selectedColorValue == color.toARGB32()
                                      ? Colors.white
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Recorded Samples Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recorded Samples',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: SonicColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (_recordedSamples.isNotEmpty)
                    GestureDetector(
                      onTap: () => setState(() => _recordedSamples.clear()),
                      child: const Text(
                        'Clear All',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: SonicColors.alertRed,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 14),

              // List of recorded sample tiles
              if (_recordedSamples.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: SonicColors.cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: SonicColors.surfaceBorder, width: 1),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: SonicColors.textMuted, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No samples recorded yet. Tap "Audio Capture" above to record 2 to 5 samples.',
                          style: TextStyle(
                            fontSize: 13,
                            color: SonicColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                for (int i = 0; i < _recordedSamples.length; i++) ...[
                  _SampleHistoryTile(
                    sampleIndex: i + 1,
                    onDelete: () => setState(() => _recordedSamples.removeAt(i)),
                  ),
                  const SizedBox(height: 10),
                ],

              const SizedBox(height: 24),

              // Save Prototype Button
              if (_recordedSamples.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _savePrototype,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SonicColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(27),
                      ),
                    ),
                    child: Text(
                      'Save Sound Prototype (${_recordedSamples.length} samples)',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SampleSlotPill extends StatelessWidget {
  final int index;
  final bool isRecorded;
  final bool isSelected;
  final VoidCallback onTap;

  const _SampleSlotPill({
    required this.index,
    required this.isRecorded,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isRecorded
              ? const Color(0xFF5E45FF)
              : isSelected
                  ? const Color(0xFF241D3F)
                  : SonicColors.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: isRecorded
                ? const Color(0xFF8D7AFF)
                : isSelected
                    ? const Color(0xFF5E45FF)
                    : SonicColors.surfaceBorder,
            width: 1,
          ),
        ),
        child: Center(
          child: isRecorded
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
              : Text(
                  'S$index',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : SonicColors.textSecondary,
                  ),
                ),
        ),
      ),
    );
  }
}

class _SampleHistoryTile extends StatelessWidget {
  final int sampleIndex;
  final VoidCallback onDelete;

  const _SampleHistoryTile({
    required this.sampleIndex,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: SonicColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SonicColors.surfaceBorder, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: SonicColors.primaryLight.withAlpha(50),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, size: 18, color: SonicColors.primaryLight),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sample $sampleIndex (3.0s capture)',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: SonicColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  '128-dim log-mel embedding ready',
                  style: TextStyle(
                    fontSize: 11,
                    color: SonicColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18, color: SonicColors.textMuted),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
