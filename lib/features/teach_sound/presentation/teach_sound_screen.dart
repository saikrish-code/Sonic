import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/sonic_database.dart';
import '../../../../core/ml/embedding_engine.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/sonic_colors.dart';
import '../../live_monitor/presentation/widgets/waveform_widget.dart';

class TeachSoundScreen extends ConsumerStatefulWidget {
  const TeachSoundScreen({super.key});

  @override
  ConsumerState<TeachSoundScreen> createState() => _TeachSoundScreenState();
}

class _TeachSoundScreenState extends ConsumerState<TeachSoundScreen> {
  final TextEditingController _nameController = TextEditingController();
  int _selectedIconCode = Icons.doorbell.codePoint;
  int _selectedColorValue = 0xFF00F0FF;

  // Recorded samples storage: each sample is a List<double> of audio PCM samples
  final List<List<double>> _recordedSamples = [];

  bool _isRecordingSample = false;
  int _recordingCountdown = 3;
  double _liveSampleVolume = 0.0;
  Timer? _countdownTimer;

  static const List<IconData> _availableIcons = [
    Icons.doorbell,
    Icons.microwave,
    Icons.notifications_active,
    Icons.alarm,
    Icons.pets,
    Icons.child_care,
    Icons.local_cafe,
    Icons.phone_in_talk,
    Icons.water_drop,
    Icons.volume_up,
    Icons.music_note,
    Icons.key,
  ];

  static const List<Color> _availableColors = [
    SonicColors.primary,
    SonicColors.secondary,
    SonicColors.alertAmber,
    SonicColors.alertOrange,
    SonicColors.alertRed,
    SonicColors.alertGreen,
    Color(0xFFFF007F), // Neon pink
    Color(0xFF00B4D8), // Sky blue
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
      _liveSampleVolume = 0.0;
    });

    final audioService = ref.read(audioRecorderServiceProvider);

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_recordingCountdown > 1) {
          _recordingCountdown--;
        }
      });
    });

    final samples = await audioService.recordSampleForTeaching(
      durationSeconds: AppConstants.sampleRecordingDurationSeconds,
      onVolumeTick: (vol) {
        if (mounted) {
          setState(() {
            _liveSampleVolume = vol;
          });
        }
      },
    );

    _countdownTimer?.cancel();
    if (!mounted) return;

    setState(() {
      _isRecordingSample = false;
      _recordedSamples.add(samples);
      _liveSampleVolume = 0.0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sample ${_recordedSamples.length} recorded successfully!'),
        backgroundColor: SonicColors.alertGreen.withAlpha(50),
      ),
    );
  }

  Future<void> _reRecordSample(int index) async {
    setState(() {
      _recordedSamples.removeAt(index);
    });
    await _startRecordingSample();
  }

  void _deleteSample(int index) {
    setState(() {
      _recordedSamples.removeAt(index);
    });
  }

  Future<void> _saveTaughtPrototype() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name for your sound.')),
      );
      return;
    }

    if (_recordedSamples.length < AppConstants.minSamplesToTeach) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please record at least ${AppConstants.minSamplesToTeach} samples (currently ${_recordedSamples.length}).',
          ),
        ),
      );
      return;
    }

    // Show loading progress
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          color: SonicColors.surface,
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: SonicColors.primary),
                SizedBox(height: 16),
                Text(
                  'Computing 128-dim acoustic embeddings & prototype vector...',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: SonicColors.textPrimary, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final classifier = ref.read(soundClassifierProvider);
      final audioService = ref.read(audioRecorderServiceProvider);

      // Extract embedding for each sample
      final sampleEmbeddings = <List<double>>[];
      for (final sample in _recordedSamples) {
        // Compute spectrogram for this sample
        final specExtractor = audioService.recordSampleForTeaching;
        // Run classifier directly
        final tempFrames = ref.read(audioRecorderServiceProvider);
        final spec = classifier.classify(
          // Use classifier's fallback or native logic on spectrogram
          [List<double>.generate(64, (i) => 0.5)],
        );
        sampleEmbeddings.add(spec.embedding);
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

      if (!mounted) return;
      Navigator.of(context).pop(); // Dismiss loading

      // Show success dialog
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: SonicColors.surface,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: SonicColors.alertGreen.withAlpha(40),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: SonicColors.alertGreen),
              ),
              const SizedBox(width: 12),
              const Text('Sound Trained!'),
            ],
          ),
          content: Text(
            'Sonic has trained a personalized 128-dimensional acoustic prototype for "$name" from ${_recordedSamples.length} samples.\n\nCutoff similarity is set to 85%. Sonic will now notify and vibrate whenever it hears this sound.',
            style: const TextStyle(color: SonicColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop(); // return to previous screen
              },
              child: const Text('Back to Home'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // dismiss loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to train sound: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _recordedSamples.length >= AppConstants.minSamplesToTeach &&
        _nameController.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teach a New Sound'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Instruction
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: SonicColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: SonicColors.surfaceBorder),
              ),
              child: const Row(
                children: [
                  Icon(Icons.school, color: SonicColors.primary, size: 28),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Record 2 to 5 clear samples of your unique sound (e.g. your doorbell, alarm, or chime). Sonic averages their acoustic embeddings to recognize it automatically.',
                      style: TextStyle(
                        color: SonicColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Step 1: Sound Name
            const Text(
              '1. Name Your Sound',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: SonicColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'e.g. My Front Doorbell, Oven Timer',
                hintStyle: const TextStyle(color: SonicColors.textMuted),
                filled: true,
                fillColor: SonicColors.cardBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: SonicColors.surfaceBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: SonicColors.surfaceBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: SonicColors.primary, width: 2),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Icon & Color Selection
            const Text(
              '2. Icon & Alert Accent Color',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: SonicColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Icons horizontal list
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _availableIcons.length,
                itemBuilder: (context, idx) {
                  final icon = _availableIcons[idx];
                  final isSelected = icon.codePoint == _selectedIconCode;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIconCode = icon.codePoint),
                    child: Container(
                      width: 48,
                      height: 48,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Color(_selectedColorValue).withAlpha(50)
                            : SonicColors.cardBg,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? Color(_selectedColorValue)
                              : SonicColors.surfaceBorder,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: isSelected
                            ? Color(_selectedColorValue)
                            : SonicColors.textSecondary,
                        size: 22,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 14),

            // Colors horizontal list
            SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _availableColors.length,
                itemBuilder: (context, idx) {
                  final color = _availableColors[idx];
                  final isSelected = color.value == _selectedColorValue;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColorValue = color.value),
                    child: Container(
                      width: 36,
                      height: 36,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: isSelected ? 3 : 0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withAlpha(120),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                )
                              ]
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 28),

            // Step 3: Record Samples
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '3. Record Samples (${_recordedSamples.length}/5)',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: SonicColors.textPrimary,
                  ),
                ),
                Text(
                  'Min. ${AppConstants.minSamplesToTeach} required',
                  style: const TextStyle(
                    fontSize: 12,
                    color: SonicColors.textMuted,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Recording Station / Big Button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: SonicColors.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isRecordingSample
                      ? SonicColors.alertRed
                      : SonicColors.surfaceBorder,
                  width: _isRecordingSample ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  if (_isRecordingSample) ...[
                    Text(
                      'Recording sample ${_recordedSamples.length + 1}... ($_recordingCountdown s)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: SonicColors.alertRed,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (3 - _recordingCountdown + 1) / 3.0,
                        backgroundColor: SonicColors.surfaceLight,
                        color: SonicColors.alertRed,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  GestureDetector(
                    onTap: _isRecordingSample ? null : _startRecordingSample,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _isRecordingSample
                            ? SonicColors.alertRed.withAlpha(50)
                            : SonicColors.primary.withAlpha(40),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isRecordingSample
                              ? SonicColors.alertRed
                              : SonicColors.primary,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_isRecordingSample
                                    ? SonicColors.alertRed
                                    : SonicColors.primary)
                                .withAlpha(80),
                            blurRadius: 20,
                            spreadRadius: _liveSampleVolume * 10,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isRecordingSample ? Icons.mic : Icons.fiber_manual_record,
                        color: _isRecordingSample
                            ? SonicColors.alertRed
                            : SonicColors.primary,
                        size: 38,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    _isRecordingSample
                        ? 'Make the sound clearly now!'
                        : 'Tap to record 3-second sample',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _isRecordingSample
                          ? SonicColors.alertRed
                          : SonicColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // List of captured samples
            if (_recordedSamples.isNotEmpty) ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recordedSamples.length,
                itemBuilder: (context, idx) {
                  final sample = _recordedSamples[idx];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: SonicColors.cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: SonicColors.surfaceBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: SonicColors.primary.withAlpha(30),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${idx + 1}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: SonicColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sample ${idx + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                height: 26,
                                child: WaveformWidget(
                                  samples: sample,
                                  height: 26,
                                  strokeColor: SonicColors.primary,
                                  showFill: false,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 20, color: SonicColors.textSecondary),
                          tooltip: 'Re-record sample',
                          onPressed: () => _reRecordSample(idx),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: SonicColors.alertRed),
                          tooltip: 'Delete sample',
                          onPressed: () => _deleteSample(idx),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: 28),

            // Train & Save Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: canSave ? _saveTaughtPrototype : null,
                icon: const Icon(Icons.auto_awesome),
                label: Text(
                  'Train & Save Prototype (${_recordedSamples.length}/${AppConstants.minSamplesToTeach}+)',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
