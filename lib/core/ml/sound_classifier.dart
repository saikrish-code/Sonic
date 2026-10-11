import 'dart:io';
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

  Interpreter? _interpreter;
  bool _isInitialized = false;
  bool _useFallback = false;
  final List<List<double>> _probHistory = [];

  bool get isInitialized => _isInitialized;
  bool get isUsingFallback => _useFallback;
  bool get hasNativeInterpreter => _interpreter != null;

  void resetSmoothing() {
    _probHistory.clear();
  }

  Future<void> init() async {
    if (_isInitialized && _interpreter != null) return;

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

    // 2. Classify dominant acoustic energy bands across the 20 categories
    final logits = <String, double>{};
    for (final cat in SoundCategories.all) {
      logits[cat.key] = _computeCategoryLogit(cat.key, meanEnergy, stdEnergy);
    }

    // Softmax to obtain probabilities
    double maxLogit = logits.values.reduce(math.max);
    double sumExp = 0.0;
    final expMap = <String, double>{};
    for (final entry in logits.entries) {
      final expVal = math.exp(entry.value - maxLogit);
      expMap[entry.key] = expVal;
      sumExp += expVal;
    }

    final probabilities = <String, double>{};
    for (final entry in expMap.entries) {
      probabilities[entry.key] = (entry.value / (sumExp > 0 ? sumExp : 1.0)).clamp(0.0, 1.0);
    }

    // Find top prediction
    String topKey = SoundCategories.all.first.key;
    double topProb = -1.0;
    for (final entry in probabilities.entries) {
      if (entry.value > topProb) {
        topProb = entry.value;
        topKey = entry.key;
      }
    }

    final topCategory = SoundCategories.getByKey(topKey);

    return ClassificationResult(
      topCategoryKey: topKey,
      topCategoryLabel: topCategory.label,
      confidence: topProb,
      embedding: embedding,
      classProbabilities: probabilities,
      timestamp: DateTime.now(),
    );
  }

  double _computeCategoryLogit(
    String key,
    List<double> meanEnergy,
    List<double> stdEnergy,
  ) {
    // Energy in low bands (0-15), mid bands (16-39), high bands (40-63)
    double lowEnergy = 0.0;
    for (int i = 0; i < 16; i++) {
      lowEnergy += meanEnergy[i];
    }
    lowEnergy /= 16;

    double midEnergy = 0.0;
    for (int i = 16; i < 40; i++) {
      midEnergy += meanEnergy[i];
    }
    midEnergy /= 24;

    double highEnergy = 0.0;
    for (int i = 40; i < meanEnergy.length; i++) {
      highEnergy += meanEnergy[i];
    }
    highEnergy /= (meanEnergy.length - 40);

    double temporalVariability = stdEnergy.reduce((a, b) => a + b) / stdEnergy.length;

    switch (key) {
      case 'smoke_alarm':
      case 'fire_alarm':
        // Piercing persistent high frequency
        return highEnergy * 3.0 - lowEnergy * 0.5;
      case 'siren':
        // Sweeping mid-to-high frequency with high temporal swing
        return midEnergy * 2.0 + temporalVariability * 2.5;
      case 'baby_crying':
        // Mid harmonic vocal bursts with high dynamics
        return midEnergy * 2.2 + temporalVariability * 2.0;
      case 'glass_breaking':
        // Sudden high-frequency shatter burst
        return highEnergy * 2.5 + temporalVariability * 3.0;
      case 'doorbell':
        // Clear mid-frequency chime
        return midEnergy * 2.4 - highEnergy * 0.5;
      case 'door_knock':
        // Short low-frequency impulse
        return lowEnergy * 3.0 + temporalVariability * 2.0;
      case 'dog_bark':
        // Low-to-mid bark bursts
        return (lowEnergy + midEnergy) * 1.5 + temporalVariability * 2.2;
      case 'phone_ringing':
        // Alternating mid-frequency ring tone
        return midEnergy * 2.5 + temporalVariability * 1.8;
      case 'name_calling':
      case 'talking':
        // Human vocal speech range (mid frequencies)
        return midEnergy * 2.0;
      case 'car_horn':
        // Loud dual-tone mid-frequency blast
        return (lowEnergy + midEnergy) * 2.0 - temporalVariability;
      case 'appliance_beep':
        // Single sharp narrow mid-high beep
        return highEnergy * 2.0 + midEnergy * 1.5;
      case 'thunderstorm':
        // Deep low-frequency rumble
        return lowEnergy * 3.5 - highEnergy * 1.0;
      case 'water_running':
        // Broad smooth continuous noise
        return (lowEnergy + midEnergy + highEnergy) * 1.0 - temporalVariability * 2.0;
      default:
        return (lowEnergy + midEnergy + highEnergy) / 3.0;
    }
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

    // Map probabilities to category keys
    final probabilities = <String, double>{};
    for (int i = 0; i < SoundCategories.all.length && i < smoothedProbs.length; i++) {
      probabilities[SoundCategories.all[i].key] = smoothedProbs[i];
    }

    // The 14 trained classes from model_info.json trained_slots (indices 0-19):
    // 2:siren, 3:baby_crying, 4:glass_breaking, 6:door_knock, 7:dog_bark,
    // 10:car_horn, 12:water_running, 13:thunderstorm, 14:alarm_clock, 15:cat_meow,
    // 16:footsteps, 17:coughing, 18:snoring, 19:danger_explosion
    const trainedKeys = {
      'siren',
      'baby_crying',
      'glass_breaking',
      'door_knock',
      'dog_bark',
      'car_horn',
      'water_running',
      'thunderstorm',
      'alarm_clock',
      'cat_meow',
      'footsteps',
      'coughing',
      'snoring',
      'danger_explosion',
    };

    // Only consider trained classes for alert-worthy predictions
    String topKey = 'ambient_silence';
    double topProb = 0.0;
    for (final key in trainedKeys) {
      final prob = probabilities[key] ?? 0.0;
      if (prob > topProb) {
        topProb = prob;
        topKey = key;
      }
    }

    // Only show alert when a trained class reaches >= 70%
    if (topProb < 0.70) {
      topKey = 'ambient_silence';
      topProb = 0.0;
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
