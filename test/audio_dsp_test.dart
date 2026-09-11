import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:soundsense/core/audio/fft.dart';
import 'package:soundsense/core/audio/mel_spectrogram.dart';

void main() {
  group('FFT Tests', () {
    test('FFT identifies dominant sinusoidal frequency', () {
      const n = 512;
      const sampleRate = 16000;
      final fft = FFT(n);

      // Generate 1000 Hz pure sine wave
      const testFreq = 1000.0;
      final samples = List<double>.generate(n, (i) {
        return math.sin(2 * math.pi * testFreq * i / sampleRate);
      });

      final powers = fft.powerSpectrum(samples);
      expect(powers.length, equals((n ~/ 2) + 1));

      // Find peak bin
      int peakBin = 0;
      double maxPower = -1.0;
      for (int i = 0; i < powers.length; i++) {
        if (powers[i] > maxPower) {
          maxPower = powers[i];
          peakBin = i;
        }
      }

      final detectedFreq = peakBin * sampleRate / n;
      // 1000 Hz with bin width 16000 / 512 = 31.25 Hz -> should be within 1 bin
      expect((detectedFreq - testFreq).abs(), lessThanOrEqualTo(32.0));
    });

    test('Hann window has symmetric bell curve and zero endpoints', () {
      final fft = FFT(512);
      final win = fft.hannWindow;
      expect(win.length, equals(512));
      expect(win[0], closeTo(0.0, 1e-4));
      expect(win[511], closeTo(0.0, 1e-4));
      expect(win[256], closeTo(1.0, 0.05));
    });
  });

  group('MelSpectrogramExtractor Tests', () {
    test('extract generates correct number of frames and 64 mel bins', () {
      final extractor = MelSpectrogramExtractor(
        sampleRate: 16000,
        nFft: 512,
        hopSize: 256,
        nMels: 64,
      );

      // 1-second silence/signal (16000 samples)
      final samples = List<double>.generate(16000, (i) => 0.1 * math.sin(i * 0.05));
      final spec = extractor.extract(samples);

      // (16000 - 512) ~/ 256 + 1 = 61 frames
      expect(spec.isNotEmpty, isTrue);
      expect(spec.length, equals(61));
      expect(spec.first.length, equals(64));

      // Check normalization
      final normalized = MelSpectrogramExtractor.normalizeForVisuals(spec);
      expect(normalized.length, equals(61));
      for (final frame in normalized) {
        for (final val in frame) {
          expect(val, inInclusiveRange(0.0, 1.0));
        }
      }
    });
  });
}
