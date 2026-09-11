import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import '../constants/app_constants.dart';
import 'audio_buffer.dart';
import 'mel_spectrogram.dart';

/// Represents a single analyzed audio frame snapshot emitted by the pipeline.
class AudioFrame {
  final List<double> samples;
  final double decibels;
  final double normalizedVolume;
  final List<List<double>> spectrogram;
  final DateTime timestamp;

  AudioFrame({
    required this.samples,
    required this.decibels,
    required this.normalizedVolume,
    required this.spectrogram,
    required this.timestamp,
  });
}

/// Service managing real-time microphone capture, streaming,
/// rolling buffer windowing, and log-mel spectrogram extraction.
class AudioRecorderService {
  AudioRecorder? _audioRecorder;
  AudioRecorder get _recorder => _audioRecorder ??= AudioRecorder();
  final AudioRingBuffer _ringBuffer = AudioRingBuffer(
    capacity: AppConstants.windowSizeSamples,
  );
  final MelSpectrogramExtractor _spectrogramExtractor = MelSpectrogramExtractor(
    sampleRate: AppConstants.sampleRate,
    nFft: AppConstants.fftSize,
    hopSize: AppConstants.hopSize,
    nMels: AppConstants.melBins,
  );

  StreamSubscription<Uint8List>? _recordSub;
  Timer? _analysisTimer;
  Timer? _simulationTimer;

  final StreamController<AudioFrame> _frameController =
      StreamController<AudioFrame>.broadcast();
  Stream<AudioFrame> get audioStream => _frameController.stream;

  bool _isListening = false;
  bool get isListening => _isListening;

  bool _isSimulationMode = false;
  bool get isSimulationMode => _isSimulationMode;

  double _simPhase = 0.0;

  /// Starts listening to microphone audio stream.
  /// If [simulation] is true or microphone is unavailable, falls back to simulated audio.
  Future<bool> startListening({bool simulation = false}) async {
    if (_isListening) return true;

    _isSimulationMode = simulation;
    _ringBuffer.clear();

    if (!simulation) {
      try {
        final hasPerm = await _recorder.hasPermission();
        if (!hasPerm) {
          debugPrint('[SonicAudio] Microphone permission denied, falling back to simulated audio');
          _startSimulationMode();
          _isListening = true;
          return true;
        }

        final stream = await _recorder.startStream(
          const RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            sampleRate: AppConstants.sampleRate,
            numChannels: 1,
            autoGain: true,
            echoCancel: true,
            noiseSuppress: false, // Keep raw environmental sounds
          ),
        );

        _recordSub = stream.listen(
          (bytes) {
            _ringBuffer.addPcm16Bytes(bytes);
          },
          onError: (error) {
            debugPrint('[SonicAudio] Stream error: $error');
            _startSimulationMode();
          },
        );

        // Analysis timer emits rolling window every 500ms
        _analysisTimer = Timer.periodic(
          const Duration(milliseconds: 500),
          (_) => _emitCurrentFrame(),
        );

        _isListening = true;
        return true;
      } catch (e) {
        debugPrint('[SonicAudio] Could not start physical mic stream: $e. Falling back to simulation.');
        _startSimulationMode();
        _isListening = true;
        return true;
      }
    } else {
      _startSimulationMode();
      _isListening = true;
      return true;
    }
  }

  void _startSimulationMode() {
    _simulationTimer?.cancel();
    _analysisTimer?.cancel();

    // Emits synthetic realistic background ambient audio
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      final sampleCount = (AppConstants.sampleRate * 0.2).toInt(); // 3200 samples
      final samples = List<double>.generate(sampleCount, (i) {
        _simPhase += 0.02;
        // Ambient noise floor + slight breathing sine wave
        final noise = (math.Random().nextDouble() - 0.5) * 0.03;
        final wave = 0.02 * math.sin(_simPhase);
        return (noise + wave).clamp(-1.0, 1.0);
      });

      _ringBuffer.addSamples(samples);
      _emitCurrentFrame();
    });
  }

  /// Injects a synthetic sound wave into the buffer (e.g. for testing & sound simulation).
  void injectSyntheticSound({
    required double frequencyHz,
    required double amplitude,
    required Duration duration,
  }) {
    final numSamples = (AppConstants.sampleRate * (duration.inMilliseconds / 1000.0)).toInt();
    final samples = List<double>.generate(numSamples, (i) {
      final t = i / AppConstants.sampleRate;
      final wave = amplitude * math.sin(2 * math.pi * frequencyHz * t);
      // Envelope decay
      final env = math.exp(-2.0 * t);
      return (wave * env).clamp(-1.0, 1.0);
    });

    _ringBuffer.addSamples(samples);
    _emitCurrentFrame();
  }

  void _emitCurrentFrame() {
    final windowSamples = _ringBuffer.getWindow();
    final rawSpec = _spectrogramExtractor.extract(windowSamples);
    final normSpec = MelSpectrogramExtractor.normalizeForVisuals(rawSpec);

    final frame = AudioFrame(
      samples: windowSamples,
      decibels: _ringBuffer.currentDecibels,
      normalizedVolume: _ringBuffer.normalizedVolume,
      spectrogram: normSpec,
      timestamp: DateTime.now(),
    );

    if (!_frameController.isClosed) {
      _frameController.add(frame);
    }
  }

  /// Records a discrete audio sample for the "Teach a Sound" workflow.
  /// Captures audio for [durationSeconds] and returns the raw normalized samples.
  Future<List<double>> recordSampleForTeaching({
    int durationSeconds = AppConstants.sampleRecordingDurationSeconds,
    void Function(double volume)? onVolumeTick,
  }) async {
    final sampleBuffer = <double>[];
    final totalSamples = AppConstants.sampleRate * durationSeconds;
    final completer = Completer<List<double>>();

    try {
      final hasPerm = await _recorder.hasPermission();
      if (!hasPerm) {
        // Fallback synthetic recording for teaching in simulated/test mode
        return _generateSyntheticTeachingSample(durationSeconds);
      }

      final tempRecorder = AudioRecorder();
      final stream = await tempRecorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: AppConstants.sampleRate,
          numChannels: 1,
        ),
      );

      late final StreamSubscription<Uint8List> sub;
      sub = stream.listen((bytes) {
        final byteData = ByteData.sublistView(bytes);
        final count = bytes.lengthInBytes ~/ 2;

        double sumSq = 0.0;
        for (int i = 0; i < count; i++) {
          final s16 = byteData.getInt16(i * 2, Endian.little);
          final norm = (s16 / 32768.0).clamp(-1.0, 1.0);
          sampleBuffer.add(norm);
          sumSq += norm * norm;
        }

        final rms = math.sqrt(sumSq / (count > 0 ? count : 1));
        final vol = (rms * 5.0).clamp(0.0, 1.0);
        onVolumeTick?.call(vol);

        if (sampleBuffer.length >= totalSamples && !completer.isCompleted) {
          sub.cancel();
          tempRecorder.stop().then((_) => tempRecorder.dispose());
          completer.complete(sampleBuffer.sublist(0, totalSamples));
        }
      }, onError: (e) {
        if (!completer.isCompleted) {
          completer.complete(_generateSyntheticTeachingSample(durationSeconds));
        }
      });

      // Safety timeout
      Future.delayed(Duration(seconds: durationSeconds + 1), () {
        if (!completer.isCompleted) {
          sub.cancel();
          tempRecorder.stop().catchError((_) => null);
          completer.complete(
            sampleBuffer.isNotEmpty
                ? sampleBuffer
                : _generateSyntheticTeachingSample(durationSeconds),
          );
        }
      });

      return await completer.future;
    } catch (e) {
      debugPrint('[SonicAudio] Direct recording failed: $e, using simulated sample.');
      return _generateSyntheticTeachingSample(durationSeconds);
    }
  }

  List<double> _generateSyntheticTeachingSample(int durationSeconds) {
    final totalSamples = AppConstants.sampleRate * durationSeconds;
    final random = math.Random();
    final baseFreq = 800.0 + random.nextDouble() * 600.0;

    return List<double>.generate(totalSamples, (i) {
      final t = i / AppConstants.sampleRate;
      final wave = 0.4 * math.sin(2 * math.pi * baseFreq * t) +
          0.2 * math.sin(2 * math.pi * (baseFreq * 1.5) * t);
      final noise = (random.nextDouble() - 0.5) * 0.05;
      return (wave + noise).clamp(-1.0, 1.0);
    });
  }

  /// Stops audio streaming.
  Future<void> stopListening() async {
    _isListening = false;
    _simulationTimer?.cancel();
    _analysisTimer?.cancel();
    await _recordSub?.cancel();
    _recordSub = null;
    try {
      if (_audioRecorder != null && await _audioRecorder!.isRecording()) {
        await _audioRecorder!.stop();
      }
    } catch (_) {}
  }

  void dispose() {
    stopListening();
    _frameController.close();
    _audioRecorder?.dispose();
  }
}
