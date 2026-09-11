import 'dart:math' as math;

/// Pure Dart implementation of Radix-2 Cooley-Tukey Fast Fourier Transform
/// and windowing functions for real-time audio analysis.
class FFT {
  final int n;
  late final List<double> _cosTable;
  late final List<double> _sinTable;
  late final List<int> _bitReverse;
  late final List<double> _hannWindow;

  FFT(this.n) {
    assert((n & (n - 1)) == 0, 'FFT size must be a power of 2');
    _initTables();
    _initHannWindow();
  }

  void _initTables() {
    _cosTable = List<double>.filled(n ~/ 2, 0.0);
    _sinTable = List<double>.filled(n ~/ 2, 0.0);
    for (int i = 0; i < n ~/ 2; i++) {
      final angle = -2.0 * math.pi * i / n;
      _cosTable[i] = math.cos(angle);
      _sinTable[i] = math.sin(angle);
    }

    _bitReverse = List<int>.filled(n, 0);
    int j = 0;
    for (int i = 0; i < n - 1; i++) {
      _bitReverse[i] = j;
      int k = n >> 1;
      while (k <= j) {
        j -= k;
        k >>= 1;
      }
      j += k;
    }
    _bitReverse[n - 1] = n - 1;
  }

  void _initHannWindow() {
    _hannWindow = List<double>.filled(n, 0.0);
    for (int i = 0; i < n; i++) {
      _hannWindow[i] = 0.5 * (1.0 - math.cos(2.0 * math.pi * i / (n - 1)));
    }
  }

  /// Returns a copy of the Hann window coefficients.
  List<double> get hannWindow => List.unmodifiable(_hannWindow);

  /// Applies the Hann window to [input] in-place or returns a windowed copy.
  List<double> applyHannWindow(List<double> input) {
    final len = math.min(input.length, n);
    final output = List<double>.filled(n, 0.0);
    for (int i = 0; i < len; i++) {
      output[i] = input[i] * _hannWindow[i];
    }
    return output;
  }

  /// Computes the forward FFT on [real] input, with zero imaginary component.
  /// Returns a tuple-like record containing [real] and [imag] lists of length [n].
  ({List<double> real, List<double> imag}) transform(List<double> input) {
    final real = List<double>.filled(n, 0.0);
    final imag = List<double>.filled(n, 0.0);

    final len = math.min(input.length, n);
    for (int i = 0; i < len; i++) {
      real[_bitReverse[i]] = input[i];
    }

    // Cooley-Tukey Radix-2 decimation-in-time
    for (int lenStep = 2; lenStep <= n; lenStep <<= 1) {
      final halfLen = lenStep >> 1;
      final tableStep = n ~/ lenStep;

      for (int i = 0; i < n; i += lenStep) {
        for (int k = 0; k < halfLen; k++) {
          final tableIdx = k * tableStep;
          final c = _cosTable[tableIdx];
          final s = _sinTable[tableIdx];

          final tr = c * real[i + k + halfLen] - s * imag[i + k + halfLen];
          final ti = s * real[i + k + halfLen] + c * imag[i + k + halfLen];

          real[i + k + halfLen] = real[i + k] - tr;
          imag[i + k + halfLen] = imag[i + k] - ti;

          real[i + k] += tr;
          imag[i + k] += ti;
        }
      }
    }

    return (real: real, imag: imag);
  }

  /// Computes the magnitude spectrum: |X[k]| = sqrt(real^2 + imag^2)
  /// Returns half-spectrum of length (n ~/ 2) + 1 (positive frequencies).
  List<double> magnitudeSpectrum(List<double> input) {
    final complex = transform(input);
    final numBins = (n ~/ 2) + 1;
    final mags = List<double>.filled(numBins, 0.0);

    for (int i = 0; i < numBins; i++) {
      final r = complex.real[i];
      final im = complex.imag[i];
      mags[i] = math.sqrt(r * r + im * im);
    }
    return mags;
  }

  /// Computes the power spectrum: |X[k]|^2 = real^2 + imag^2
  List<double> powerSpectrum(List<double> input) {
    final complex = transform(input);
    final numBins = (n ~/ 2) + 1;
    final powers = List<double>.filled(numBins, 0.0);

    for (int i = 0; i < numBins; i++) {
      final r = complex.real[i];
      final im = complex.imag[i];
      powers[i] = (r * r + im * im) / n;
    }
    return powers;
  }
}
