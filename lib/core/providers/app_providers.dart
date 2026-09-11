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
import '../ml/sound_classifier.dart';
import '../ml/sound_labels.dart';
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

class DetectionCoordinator {
  final Ref _ref;
  StreamSubscription? _audioSub;

  DetectionCoordinator(this._ref) {
    _startObserving();
  }

  void _startObserving() {
    final audioService = _ref.read(audioRecorderServiceProvider);
    _audioSub = audioService.audioStream.listen((frame) async {
      final isListening = _ref.read(isListeningActiveProvider);
      if (!isListening) return;

      // 1. Run General Sound Classifier
      final classifier = _ref.read(soundClassifierProvider);
      final classification = classifier.classify(frame.spectrogram);
      _ref.read(latestDetectionProvider.notifier).state = classification;

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

      // 3. Evaluate General Sound Detection if confident
      final cat = SoundCategories.getByKey(classification.topCategoryKey);
      if (classification.confidence >= cat.defaultThreshold &&
          classification.topCategoryKey != 'ambient_silence') {
        await alertService.triggerAlert(
          soundKey: cat.key,
          soundName: cat.label,
          category: cat.urgency.name.toUpperCase(),
          confidence: classification.confidence,
          isPersonal: false,
          color: cat.color,
          icon: cat.icon,
        );
      }
    });
  }

  void dispose() {
    _audioSub?.cancel();
  }
}
