import 'dart:io';
import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:soundsense/core/audio/mel_spectrogram.dart';
import 'package:soundsense/core/ml/embedding_engine.dart';
import 'package:soundsense/core/ml/sound_classifier.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TFLite Model Integration & SoundClassifier Tests', () {
    test('sound_classifier.tflite asset exists and has valid TFLite structure', () async {
      final modelFile = File('assets/models/sound_classifier.tflite');
      expect(modelFile.existsSync(), isTrue);

      final bytes = await modelFile.readAsBytes();
      expect(bytes.length, greaterThan(1500000)); // ~1.78 MB

      final interpreter = Interpreter.fromBuffer(bytes);
      expect(interpreter, isNotNull);

      final inputDetails = interpreter.getInputTensors();
      final outputDetails = interpreter.getOutputTensors();

      expect(inputDetails.length, equals(1));
      expect(inputDetails.first.shape, equals([1, 61, 64]));

      expect(outputDetails.length, equals(2));
      expect(outputDetails[0].shape, equals([1, 20]));
      expect(outputDetails[1].shape, equals([1, 128]));

      interpreter.close();
    });

    test('SoundClassifier initializes native TFLite interpreter from asset', () async {
      final classifier = SoundClassifier();
      await classifier.init();

      expect(classifier.isInitialized, isTrue);
      expect(classifier.isUsingFallback, isFalse);
      expect(classifier.hasNativeInterpreter, isTrue);

      classifier.dispose();
    });

    test('SoundClassifier classifies exact 61x64 log-mel spectrogram', () async {
      final classifier = SoundClassifier();
      await classifier.init();

      // Synthesize 61 frames of 64 mel values (typical background energy ~ -3.5 log10)
      final spec = List.generate(
        61,
        (_) => List.generate(64, (m) => -3.5 + 0.1 * math.sin(m.toDouble())),
      );

      final result = classifier.classify(spec);

      expect(result.isNativeTflite, isTrue);
      expect(result.classProbabilities.length, equals(20));
      expect(result.embedding.length, equals(128));

      // Embedding should be normalized unit vector (L2 norm ~ 1.0)
      double sumSq = 0.0;
      for (final v in result.embedding) {
        sumSq += v * v;
      }
      expect(math.sqrt(sumSq), closeTo(1.0, 0.05));

      // All probabilities should be valid numbers between 0.0 and 1.0
      for (final prob in result.classProbabilities.values) {
        expect(prob, greaterThanOrEqualTo(0.0));
        expect(prob, lessThanOrEqualTo(1.0));
      }

      classifier.dispose();
    });

    test('SoundClassifier gracefully handles partial and oversized spectrograms', () async {
      final classifier = SoundClassifier();
      await classifier.init();

      // 1. Partial frames (30 frames instead of 61) - padded internally
      final shortSpec = List.generate(
        30,
        (_) => List.generate(64, (m) => -4.0),
      );
      final shortResult = classifier.classify(shortSpec);
      expect(shortResult.isNativeTflite, isTrue);
      expect(shortResult.embedding.length, equals(128));

      // 2. Oversized frames (120 frames instead of 61) - windowed internally
      final longSpec = List.generate(
        120,
        (_) => List.generate(64, (m) => -3.0),
      );
      final longResult = classifier.classify(longSpec);
      expect(longResult.isNativeTflite, isTrue);
      expect(longResult.embedding.length, equals(128));

      classifier.dispose();
    });

    test('End-to-end DSP -> Spectrogram -> TFLite Inference -> Prototype Matching pipeline', () async {
      final classifier = SoundClassifier();
      await classifier.init();

      final extractor = MelSpectrogramExtractor();

      // Generate 1-second sine wave at 800 Hz (16000 samples)
      final samples = List.generate(16000, (i) {
        final t = i / 16000.0;
        return 0.5 * math.sin(2 * math.pi * 800 * t);
      });

      final rawSpec = extractor.extract(samples);
      expect(rawSpec.length, equals(61));
      expect(rawSpec.first.length, equals(64));

      final result = classifier.classify(rawSpec);
      expect(result.isNativeTflite, isTrue);
      expect(result.embedding.length, equals(128));

      // Test cosine similarity of self-matching
      final sim = EmbeddingEngine.cosineSimilarity(result.embedding, result.embedding);
      expect(sim, closeTo(1.0, 0.001));

      classifier.dispose();
    });
  });
}
