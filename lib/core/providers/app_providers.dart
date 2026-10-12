import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../alert/alert_service.dart';
import '../alert/notification_service.dart';
import '../alert/vibration_service.dart';
import '../audio/audio_recorder_service.dart';
import '../ble/ble_device_model.dart';
import '../ble/ble_service.dart';
import '../database/sonic_database.dart';
import '../ml/embedding_engine.dart';
import '../ml/live_status.dart';
import '../ml/sound_classifier.dart';
import '../theme/sonic_icons.dart';

// --- SERVICE PROVIDERS (SINGLETONS) ---

final databaseProvider = Provider<SonicDatabase>((ref) {
  throw UnimplementedError('databaseProvider must be initialized in main()');
});

final vibrationServiceProvider = Provider<VibrationService>((ref) {
  final service = VibrationService();
  service.init();
  return service;
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService();
  service.init();
  return service;
});

final soundClassifierProvider = Provider<SoundClassifier>((ref) {
  final classifier = SoundClassifier();
  classifier.init();
  return classifier;
});

final alertServiceProvider = Provider<AlertService>((ref) {
  final vib = ref.watch(vibrationServiceProvider);
  final notif = ref.watch(notificationServiceProvider);
  final db = ref.watch(databaseProvider);
  return AlertService(
    vibrationService: vib,
    notificationService: notif,
    database: db,
  );
});

final bleServiceProvider = Provider<BleService>((ref) {
  final service = BleService();
  ref.onDispose(() => service.dispose());
  return service;
});

final audioRecorderServiceProvider = Provider<AudioRecorderService>((ref) {
  final recorder = AudioRecorderService();
  ref.onDispose(() => recorder.dispose());
  return recorder;
});

// --- AUDIO PIPELINE & DETECTION STATE ---

/// Emits live audio frames (samples, amplitude in dB, normalized volume, log-mel spectrogram)
final liveAudioStreamProvider = StreamProvider<AudioFrame>((ref) {
  final recorder = ref.watch(audioRecorderServiceProvider);
  return recorder.audioStream;
});

/// Whether the app is actively listening to audio
final isListeningActiveProvider = StateProvider<bool>((ref) => true);

/// Microphone hardware state stream (idle, listening, paused, permissionDenied,
/// microphoneError, simulationMode). Single source of truth for audio source health.
final microphoneStateProvider = StreamProvider<MicrophoneState>((ref) {
  final recorder = ref.watch(audioRecorderServiceProvider);
  return recorder.microphoneStateStream;
});

/// Current microphone state value for synchronous reads inside other providers.
final microphoneStateValueProvider = StateProvider<MicrophoneState>((ref) => MicrophoneState.idle);

/// Current active heads-up alert banner (with screen flash overlay)
final activeAlertBannerProvider = StreamProvider<ActiveAlertBanner?>((ref) {
  final alertService = ref.watch(alertServiceProvider);
  return alertService.activeBannerStream;
});

/// Reactive stream of all user-taught sounds from Drift SQLite database
final allTaughtSoundsProvider = StreamProvider<List<TaughtSound>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllTaughtSounds();
});

/// Reactive stream of past alert history entries
final alertHistoryProvider = StreamProvider<List<AlertHistoryData>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAlertHistory();
});

/// Latest classification result from the general ML model
final latestDetectionProvider = StateProvider<ClassificationResult?>((ref) => null);

/// Latest smoothed decibel reading from the live audio stream for Normal/Talking.
final latestDecibelsProvider = StateProvider<double?>((ref) => null);

/// Live microphone decibel reading stream for Normal/Talking baseline tracking.
/// Carries raw decibel values from audio frames.
/// Single shared live sound status (exactly one state at a time) derived from
/// mic state, listening toggle, classifier output, and decibel level.
final liveSoundStatusProvider = StateProvider<LiveSoundStatus>((ref) {
  final micState = ref.watch(microphoneStateValueProvider);
  final isListening = ref.watch(isListeningActiveProvider);
  final detection = ref.watch(latestDetectionProvider);
  final decibels = ref.watch(latestDecibelsProvider);

  final resolver = ref.read(liveStatusResolverProvider);
  return resolver.resolve(
    micState: micState,
    isListening: isListening,
    detection: detection,
    decibels: decibels,
  );
});

final liveStatusResolverProvider = Provider<LiveStatusResolver>((ref) {
  return LiveStatusResolver();
});

/// Real-time cosine similarity scores for all taught sounds: prototypeId -> similarity [0.0, 1.0]
final livePrototypeSimilarityProvider = StateProvider<Map<String, double>>((ref) => {});

/// BLE Discovered Devices
final bleScanResultsProvider = StreamProvider<List<BleDeviceModel>>((ref) {
  final ble = ref.watch(bleServiceProvider);
  return ble.scanResultsStream;
});

/// Active connected BLE device
final bleConnectedDeviceProvider = StreamProvider<BleDeviceModel?>((ref) {
  final ble = ref.watch(bleServiceProvider);
  return ble.connectedDeviceStream;
});

/// Live Detection & Matching Coordinator that observes live audio frames
/// and evaluates both the general classifier and few-shot prototype matcher
final detectionCoordinatorProvider = Provider<DetectionCoordinator>((ref) {
  return DetectionCoordinator(ref);
});

/// Bridges the microphone state stream into a synchronous state value and
/// refreshes the shared live status whenever the mic state changes.
final micStateBridgeProvider = Provider<void>((ref) {
  final recorder = ref.read(audioRecorderServiceProvider);
  final sub = recorder.microphoneStateStream.listen((state) {
    try {
      ref.read(microphoneStateValueProvider.notifier).state = state;
      final isListening = ref.read(isListeningActiveProvider);
      final detection = ref.read(latestDetectionProvider);
      final decibels = ref.read(latestDecibelsProvider);
      final resolver = ref.read(liveStatusResolverProvider);
      ref.read(liveSoundStatusProvider.notifier).state = resolver.resolve(
        micState: state,
        isListening: isListening,
        detection: detection,
        decibels: decibels,
      );
    } catch (_) {}
  });
  ref.onDispose(sub.cancel);
  // Seed with the service's current state so the status is correct on boot.
  try {
    ref.read(microphoneStateValueProvider.notifier).state =
        recorder.currentMicState;
  } catch (_) {}
  return;
});

/// Ensures the audio pipeline starts when the app reaches the dashboard,
/// including after onboarding was already completed on a previous launch.
final audioPipelineBootstrapProvider = Provider<void>((ref) {
  final recorder = ref.read(audioRecorderServiceProvider);
  ref.read(detectionCoordinatorProvider);
  ref.read(micStateBridgeProvider);
  Future.microtask(() async {
    try {
      await recorder.startListening();
    } catch (_) {}
  });
  return;
});

class DetectionCoordinator {
  final Ref _ref;
  StreamSubscription? _audioSub;

  DetectionCoordinator(this._ref) {
    _ref.listen<bool>(isListeningActiveProvider, (previous, isListening) {
      if (!isListening) {
        _ref.read(soundClassifierProvider).resetSmoothing();
      }
    });
    _startObserving();
  }

  void _startObserving() {
    final audioService = _ref.read(audioRecorderServiceProvider);
    _audioSub = audioService.audioStream.listen((frame) async {
      final isListening = _ref.read(isListeningActiveProvider);
      if (!isListening) {
        _refreshLiveStatus();
        return;
      }

      // 1. Run General Sound Classifier
      final classifier = _ref.read(soundClassifierProvider);
      final classification = classifier.classify(frame.rawSpectrogram);
      _ref.read(latestDetectionProvider.notifier).state = classification;
      _ref.read(latestDecibelsProvider.notifier).state = frame.decibels;
      _refreshLiveStatus();

      final alertService = _ref.read(alertServiceProvider);

      // 2. Run Few-Shot Personal Sound Matcher against taught prototypes
      final taughtSoundsAsync = _ref.read(allTaughtSoundsProvider);
      final prototypes = taughtSoundsAsync.asData?.value ?? [];

      if (prototypes.isNotEmpty) {
        // Update live similarity gauges for debug view
        final gaugeScores = EmbeddingEngine.computeSimilarityGauges(
          liveEmbedding: classification.embedding,
          prototypes: prototypes,
        );
        _ref.read(livePrototypeSimilarityProvider.notifier).state = gaugeScores;

        // Evaluate matches
        final matches = EmbeddingEngine.matchLiveEmbedding(
          liveEmbedding: classification.embedding,
          prototypes: prototypes,
        );

        final triggered = matches.where((m) => m.isTriggered).toList();
        if (triggered.isNotEmpty) {
          final topMatch = triggered.first;
          await alertService.triggerAlert(
            soundKey: topMatch.sound.id,
            soundName: topMatch.sound.name,
            category: 'Personal Sound',
            confidence: topMatch.similarity,
            isPersonal: true,
            prototypeId: topMatch.sound.id,
            color: Color(topMatch.sound.colorValue),
            icon: getDynamicIcon(topMatch.sound.iconCode),
          );
          return; // Personal match takes priority
        }
      }

      // 3. Trigger the general alert only for the single shared live status.
      final status = _ref.read(liveSoundStatusProvider);
      if (status.showsEvent && status.category != null) {
        final cat = status.category!;
        await alertService.triggerAlert(
          soundKey: cat.key,
          soundName: cat.label,
          category: cat.urgency.name.toUpperCase(),
          confidence: status.confidence,
          isPersonal: false,
          color: cat.color,
          icon: cat.icon,
        );
      }
    });
  }

  void _refreshLiveStatus() {
    final micState = _ref.read(microphoneStateValueProvider);
    final isListening = _ref.read(isListeningActiveProvider);
    final detection = _ref.read(latestDetectionProvider);
    final decibels = _ref.read(latestDecibelsProvider);
    final resolver = _ref.read(liveStatusResolverProvider);
    _ref.read(liveSoundStatusProvider.notifier).state = resolver.resolve(
      micState: micState,
      isListening: isListening,
      detection: detection,
      decibels: decibels,
    );
  }

  void dispose() {
    _audioSub?.cancel();
  }
}
