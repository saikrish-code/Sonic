import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../constants/app_constants.dart';
import 'embedding_engine.dart';
import 'sound_labels.dart';

/// Result of sound inference containing class prediction and 128-dim embedding.
class ClassificationResult {
  final String topCategoryKey;
  final String topCategoryLabel;
  final double confidence;
  final List<double> embedding;
  final Map<String, double> classProbabilities;
  final DateTime timestamp;
  final bool isNativeTflite;

  const ClassificationResult({
    required this.topCategoryKey,
    required this.topCategoryLabel,
    required this.confidence,
    required this.embedding,
    required this.classProbabilities,
    required this.timestamp,
    this.isNativeTflite = false,
  });

  bool get isConfident => confidence >= 0.65;
}

/// Dual-output General Sound Classifier running quantized TFLite inference
/// with an on-device spectral feature fallback engine.
class SoundClassifier {
  static const int expectedFrames = 61;
  static const int melBins = 64;
  static const int smoothingWindowSize = 3;

  static const double eventThreshold = 0.70;
  static const int eventAgreementWindow = 3;
  static const int eventAgreementRequired = 2;

  /// Only these model slots may become live dashboard events.
  static const Set<String> targetEventKeys = {
    'door_knock',
    'coughing',
    'baby_crying',
    'dog_bark',
    'cat_meow',
    'footsteps',
  };

  Interpreter? _interpreter;
  bool _isInitialized = false;
  bool _useFallback = false;
  double _activeEventThreshold = eventThreshold;
  Map<String, double> _targetThresholds = Map.of({
    'door_knock': 0.70,
    'coughing': 0.70,
    'baby_crying': 0.70,
    'dog_bark': 0.70,
    'cat_meow': 0.70,
    'footsteps': 0.70,
  });
  final List<List<double>> _probHistory = [];
  final List<MapEntry<String, double>?> _eventHistory = [];

  bool get isInitialized => _isInitialized;
  bool get isUsingFallback => _useFallback;
  bool get hasNativeInterpreter => _interpreter != null;
  double get activeEventThreshold => _activeEventThreshold;

  /// Per-target-class thresholds set from Settings. Values below the metadata
  /// floor of 0.70 are clamped up on read; the metadata minimum stays in force.
  void setTargetThresholds(Map<String, double> thresholds) {
    _targetThresholds = Map.of(_targetThresholds)..addAll(thresholds);
  }

  double thresholdFor(String key) =>
      (_targetThresholds[key] ?? _activeEventThreshold).clamp(0.70, 0.95).toDouble();

  void resetSmoothing() {
    _probHistory.clear();
    _eventHistory.clear();
  }

  Future<void> init() async {
    if (_isInitialized && _interpreter != null) return;

    try {
      final metadata = jsonDecode(
        await rootBundle.loadString('assets/models/model_info.json'),
      );
      if (metadata is Map<String, dynamic> &&
          metadata['recommended_threshold'] is num) {
        _activeEventThreshold = (metadata['recommended_threshold'] as num)
            .toDouble()
            .clamp(eventThreshold, 0.99)
            .toDouble();
      }
    } catch (e) {
      debugPrint('[SonicML] Could not read model threshold metadata: $e. Using 0.70.');
      _activeEventThreshold = eventThreshold;
    }

    try {
      const assetPath = 'assets/models/sound_classifier.tflite';
      Uint8List? buffer;
      try {
        final byteData = await rootBundle.load(assetPath);
        buffer = byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        );
      } catch (bundleErr) {
        debugPrint('[SonicML] rootBundle load failed for $assetPath: $bundleErr. Trying File system...');
        final file = File(assetPath);
        if (file.existsSync()) {
          buffer = await file.readAsBytes();
        }
      }

      if (buffer != null && buffer.length > 100000) {
        _interpreter = Interpreter.fromBuffer(buffer);
        _isInitialized = true;
        _useFallback = false;
        debugPrint('[SonicML] Successfully loaded native TFLite sound_classifier.tflite (${buffer.length} bytes)');
        return;
      } else {
        debugPrint('[SonicML] Native TFLite asset not found or empty. Using acoustic fallback engine.');
        _useFallback = true;
        _isInitialized = true;
      }
    } catch (e) {
      debugPrint('[SonicML] Classifier init error ($e). Using acoustic fallback engine.');
      _useFallback = true;
      _isInitialized = true;
    }
  }

  /// Classifies a log-mel spectrogram matrix and extracts its 128-dim embedding.
  ClassificationResult classify(List<List<double>> spectrogram) {
    if (spectrogram.isEmpty) {
      return ClassificationResult(
        topCategoryKey: 'ambient_silence',
        topCategoryLabel: 'Ambient Silence',
        confidence: 0.0,
        embedding: List<double>.filled(AppConstants.embeddingDimension, 0.0),
        classProbabilities: {},
        timestamp: DateTime.now(),
      );
    }

    if (!_useFallback && _interpreter != null) {
      try {
        return _runNativeTflite(spectrogram);
      } catch (e) {
        debugPrint('[SonicML] Native inference failed ($e), using fallback engine');
        return _runAcousticFallback(spectrogram);
      }
    } else {
      return _runAcousticFallback(spectrogram);
    }
  }

  /// Runs inference using on-device acoustic feature extraction
  ClassificationResult _runAcousticFallback(List<List<double>> spectrogram) {
    final numFrames = spectrogram.length;
    final numMels = spectrogram.first.length; // usually 64

    // 1. Calculate per-mel band statistics: mean (64) + std dev (64) = 128 dimensions
    final meanEnergy = List<double>.filled(numMels, 0.0);
    final stdEnergy = List<double>.filled(numMels, 0.0);

    for (int m = 0; m < numMels; m++) {
      double sum = 0.0;
      for (int f = 0; f < numFrames; f++) {
        sum += spectrogram[f][m];
      }
      meanEnergy[m] = sum / numFrames;

      double sumSqDiff = 0.0;
      for (int f = 0; f < numFrames; f++) {
        final diff = spectrogram[f][m] - meanEnergy[m];
        sumSqDiff += diff * diff;
      }
      stdEnergy[m] = math.sqrt(sumSqDiff / numFrames);
    }

    // Combine into 128-dim vector
    final rawEmbedding = <double>[];
    rawEmbedding.addAll(meanEnergy);
    rawEmbedding.addAll(stdEnergy);

    // L2 normalize
    final embedding = EmbeddingEngine.l2Normalize(rawEmbedding);

    // This energy-only fallback has no trained class boundaries. Keep its
    // embedding for Teach a Sound, but never present its heuristic guess as a
    // real event (that is especially prone to false cough labels).
    _probHistory.clear();
    _eventHistory.clear();
    return ClassificationResult(
      topCategoryKey: 'ambient_silence',
      topCategoryLabel: 'Normal',
      confidence: 0.0,
      embedding: embedding,
      classProbabilities: const {},
      timestamp: DateTime.now(),
    );
  }

  ClassificationResult _runNativeTflite(List<List<double>> spectrogram) {
    // Model shapes: Input [1, 61, 64]
    // Output 0: [1, 20] classes
    // Output 1: [1, 128] embeddings
    final List<List<double>> windowFrames;
    if (spectrogram.length > expectedFrames) {
      // Take the most recent 61 frames
      windowFrames = spectrogram.sublist(spectrogram.length - expectedFrames);
    } else {
      windowFrames = spectrogram;
    }

    final formattedInput = List.generate(1, (_) {
      return List.generate(expectedFrames, (f) {
        if (f < windowFrames.length) {
          final frame = windowFrames[f];
          if (frame.length == melBins) {
            return List<double>.from(frame);
          } else if (frame.length > melBins) {
            return frame.sublist(0, melBins);
          } else {
            return [...frame, ...List<double>.filled(melBins - frame.length, -6.0)];
          }
        } else {
          return List<double>.filled(melBins, -6.0);
        }
      });
    });

    final outputClasses = List.generate(1, (_) => List<double>.filled(20, 0.0));
    final outputEmbeddings = List.generate(1, (_) => List<double>.filled(128, 0.0));

    final outputs = {
      0: outputClasses,
      1: outputEmbeddings,
    };

    _interpreter!.runForMultipleInputs([formattedInput], outputs);

    final rawProbs = outputClasses[0];
    final embedding = EmbeddingEngine.l2Normalize(outputEmbeddings[0]);

    // Average the last 3 outputs (recommended in model_info.json)
    _probHistory.add(List<double>.from(rawProbs));
    if (_probHistory.length > smoothingWindowSize) {
      _probHistory.removeAt(0);
    }

    final smoothedProbs = List<double>.filled(rawProbs.length, 0.0);
    for (final past in _probHistory) {
      for (int i = 0; i < rawProbs.length; i++) {
        smoothedProbs[i] += past[i] / _probHistory.length;
      }
    }

    // Map probabilities to category keys in the exact model output order.
    final probabilities = <String, double>{};
    for (int i = 0; i < SoundCategories.all.length && i < smoothedProbs.length; i++) {
      probabilities[SoundCategories.all[i].key] = smoothedProbs[i];
    }

    // Model metadata from assets/models/model_info.json:
    // - 20 output indices (0-19) map to the exact category order in "categories"
    // - 14 trained classes at "trained_slots": [2,3,4,6,7,10,12,13,14,15,16,17,18,19]
    // - 6 untrained: smoke_alarm(0), fire_alarm(1), doorbell(5), phone_ringing(8),
    //   name_calling(9), appliance_beep(11) - not reliable for inference
    // - Current metadata threshold: 0.70 (validation-selected for 5% false alarms);
    //   init() allows metadata to raise it but never below the 0.70 minimum.
    //
    // The 6 intended dashboard event classes must all be verified trained:
    // door_knock(6), coughing(17), baby_crying(3), dog_bark(7), cat_meow(15),
    // footsteps(16) - ALL PRESENT in trained_slots ✓
    // Only consider the 6 target event classes for the dashboard display.
    // Show the highest-confidence target only when it reaches the active metadata threshold.
    String topKey = 'ambient_silence';
    double topProb = 0.0;
    for (final key in targetEventKeys) {
      final prob = probabilities[key] ?? 0.0;
      if (prob > topProb) {
        topProb = prob;
        topKey = key;
      }
    }

    final qualifiedCandidate =
        topProb >= thresholdFor(topKey) ? MapEntry(topKey, topProb) : null;
    _eventHistory.add(qualifiedCandidate);
    if (_eventHistory.length > eventAgreementWindow) {
      _eventHistory.removeAt(0);
    }

    final agreeingScores = _eventHistory
        .where((entry) => entry?.key == topKey)
        .map((entry) => entry!.value)
        .toList();
    final hasTemporalAgreement = qualifiedCandidate != null &&
        agreeingScores.length >= eventAgreementRequired;

    // Require both >=70% confidence and the same event in at least two of
    // three overlapping windows. Otherwise let the live status layer decide
    // between Normal (baseline) and Talking (decibel departure).
    if (!hasTemporalAgreement) {
      topKey = 'ambient_silence';
      topProb = 0.0;
    } else {
      topProb = agreeingScores.reduce((a, b) => a + b) / agreeingScores.length;
    }

    return ClassificationResult(
      topCategoryKey: topKey,
      topCategoryLabel: SoundCategories.getByKey(topKey).label,
      confidence: topProb,
      embedding: embedding,
      classProbabilities: probabilities,
      timestamp: DateTime.now(),
      isNativeTflite: true,
    );
  }

  void dispose() {
    _interpreter?.close();
  }
}
