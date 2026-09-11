import 'dart:math' as math;
import 'dart:typed_data';

/// Ring buffer that maintains a rolling window of normalized audio samples
/// and computes real-time amplitude metrics (RMS / decibels).
class AudioRingBuffer {
  final int capacity;
  final Float64List _buffer;
  int _writeIndex = 0;
  int _totalSamplesWritten = 0;

  AudioRingBuffer({this.capacity = 16000}) : _buffer = Float64List(capacity);

  /// Whether the buffer has filled at least once with a complete window.
  bool get isFull => _totalSamplesWritten >= capacity;

  /// Total number of samples written since initialization or reset.
  int get totalSamplesWritten => _totalSamplesWritten;

  /// Appends raw 16-bit signed PCM little-endian byte stream to the ring buffer.
  void addPcm16Bytes(Uint8List bytes) {
    final byteData = ByteData.sublistView(bytes);
    final numSamples = bytes.lengthInBytes ~/ 2;

    for (int i = 0; i < numSamples; i++) {
      final sampleInt16 = byteData.getInt16(i * 2, Endian.little);
      final sampleNormalized = (sampleInt16 / 32768.0).clamp(-1.0, 1.0);
      _buffer[_writeIndex] = sampleNormalized;
      _writeIndex = (_writeIndex + 1) % capacity;
      _totalSamplesWritten++;
    }
  }

  /// Appends normalized floating point samples [-1.0, 1.0].
  void addSamples(List<double> samples) {
    for (int i = 0; i < samples.length; i++) {
      _buffer[_writeIndex] = samples[i].clamp(-1.0, 1.0);
      _writeIndex = (_writeIndex + 1) % capacity;
      _totalSamplesWritten++;
    }
  }

  /// Returns the latest [capacity] samples chronologically ordered.
  List<double> getWindow() {
    final result = List<double>.filled(capacity, 0.0);
    if (!isFull) {
      // Partial window from start to writeIndex
      for (int i = 0; i < _writeIndex; i++) {
        result[i] = _buffer[i];
      }
      return result;
    }

    // Chronological order: oldest is at _writeIndex, newest is at (_writeIndex - 1)
    for (int i = 0; i < capacity; i++) {
      final idx = (_writeIndex + i) % capacity;
      result[i] = _buffer[idx];
    }
    return result;
  }

  /// Computes Root-Mean-Square (RMS) amplitude of the current window.
  double get currentRms {
    final count = isFull ? capacity : math.max(_writeIndex, 1);
    double sumSquares = 0.0;
    for (int i = 0; i < count; i++) {
      final val = _buffer[i];
      sumSquares += val * val;
    }
    return math.sqrt(sumSquares / count);
  }

  /// Computes amplitude in decibels (dB), clamped between -80 dB and 0 dB.
  double get currentDecibels {
    final rms = currentRms;
    if (rms <= 1e-5) return -80.0;
    final db = 20.0 * (math.log(rms) / math.ln10);
    return db.clamp(-80.0, 0.0);
  }

  /// Returns a normalized audio level in [0.0, 1.0] for UI meters.
  double get normalizedVolume {
    final db = currentDecibels;
    // Map -60 dB to 0.0 and 0 dB to 1.0
    final norm = (db + 60.0) / 60.0;
    return norm.clamp(0.0, 1.0);
  }

  /// Clears the ring buffer.
  void clear() {
    _buffer.fillRange(0, capacity, 0.0);
    _writeIndex = 0;
    _totalSamplesWritten = 0;
  }
}
