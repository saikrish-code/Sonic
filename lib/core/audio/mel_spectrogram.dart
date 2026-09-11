import 'dart:math' as math;
import 'fft.dart';

/// Pure Dart implementation of Log-Mel Spectrogram transformation
/// designed for low-latency on-device audio feature extraction.
class MelSpectrogramExtractor {
  final int sampleRate;
  final int nFft;
  final int hopSize;
  final int nMels;
  final double fMin;
  final double fMax;

  late final FFT _fft;
  late final List<List<double>> _melFilterBank; // [nMels, (nFft / 2) + 1]

  MelSpectrogramExtractor({
    this.sampleRate = 16000,
    this.nFft = 512,
    this.hopSize = 256,
    this.nMels = 64,
    this.fMin = 50.0,
    this.fMax = 8000.0,
  }) {
    _fft = FFT(nFft);
    _buildMelFilterBank();
  }

  /// Converts frequency in Hz to Mel scale
  static double hzToMel(double hz) {
    return 2595.0 * (math.log(1.0 + hz / 700.0) / math.ln10);
  }

  /// Converts Mel scale to frequency in Hz
  static double melToHz(double mel) {
    return 700.0 * (math.pow(10.0, mel / 2595.0) - 1.0);
  }

  void _buildMelFilterBank() {
    final numBins = (nFft ~/ 2) + 1;
    final minMel = hzToMel(fMin);
    final maxMel = hzToMel(fMax);

    // Mels points evenly spaced
    final melPoints = List<double>.filled(nMels + 2, 0.0);
    final melStep = (maxMel - minMel) / (nMels + 1);
    for (int i = 0; i < nMels + 2; i++) {
      melPoints[i] = minMel + i * melStep;
    }

    // Convert to FFT bin indices
    final binPoints = List<int>.filled(nMels + 2, 0);
    for (int i = 0; i < nMels + 2; i++) {
      final hz = melToHz(melPoints[i]);
      final bin = ((hz / sampleRate) * nFft).round();
      binPoints[i] = bin.clamp(0, numBins - 1);
    }

    // Construct triangular filters
    _melFilterBank = List.generate(
      nMels,
      (m) => List<double>.filled(numBins, 0.0),
    );

    for (int m = 1; m <= nMels; m++) {
      final left = binPoints[m - 1];
      final center = binPoints[m];
      final right = binPoints[m + 1];

      // Ascending slope
      if (center > left) {
        for (int k = left; k < center; k++) {
          _melFilterBank[m - 1][k] = (k - left) / (center - left);
        }
      }

      // Descending slope
      if (right > center) {
        for (int k = center; k <= right; k++) {
          _melFilterBank[m - 1][k] = (right - k) / (right - center);
        }
      }
    }
  }

  /// Computes log-mel spectrogram matrix from mono audio PCM samples.
  /// Output: List of frames, where each frame is a List<double> of length [nMels].
  List<List<double>> extract(List<double> samples) {
    if (samples.length < nFft) {
      return [];
    }

    final numFrames = ((samples.length - nFft) ~/ hopSize) + 1;
    final spectrogram = <List<double>>[];
    final frameBuffer = List<double>.filled(nFft, 0.0);

    for (int f = 0; f < numFrames; f++) {
      final offset = f * hopSize;
      for (int i = 0; i < nFft; i++) {
        frameBuffer[i] = samples[offset + i];
      }

      // 1. Apply Hann window
      final windowed = _fft.applyHannWindow(frameBuffer);

      // 2. Power spectrum
      final powers = _fft.powerSpectrum(windowed);

      // 3. Dot product with Mel filterbank & log compression
      final melFrame = List<double>.filled(nMels, 0.0);
      for (int m = 0; m < nMels; m++) {
        double melEnergy = 0.0;
        final filter = _melFilterBank[m];
        for (int k = 0; k < powers.length; k++) {
          melEnergy += filter[k] * powers[k];
        }
        // Log compression: log10(max(energy, 1e-6))
        melFrame[m] = math.log(math.max(melEnergy, 1e-6)) / math.ln10;
      }

      spectrogram.add(melFrame);
    }

    return spectrogram;
  }

  /// Normalizes a log-mel spectrogram into [0.0, 1.0] range for heatmap rendering.
  static List<List<double>> normalizeForVisuals(List<List<double>> spec) {
    if (spec.isEmpty) return [];
    double minVal = double.infinity;
    double maxVal = double.negativeInfinity;

    for (final frame in spec) {
      for (final val in frame) {
        if (val < minVal) minVal = val;
        if (val > maxVal) maxVal = val;
      }
    }

    final range = maxVal - minVal;
    if (range <= 1e-6) {
      return List.generate(
        spec.length,
        (i) => List<double>.filled(spec[i].length, 0.0),
      );
    }

    return spec.map((frame) {
      return frame.map((val) => ((val - minVal) / range).clamp(0.0, 1.0)).toList();
    }).toList();
  }
}
