import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundsense/app.dart';
import 'package:soundsense/core/alert/alert_service.dart';
import 'package:soundsense/core/alert/notification_service.dart';
import 'package:soundsense/core/alert/vibration_service.dart';
import 'package:soundsense/core/audio/audio_recorder_service.dart';
import 'package:soundsense/core/ble/ble_service.dart';
import 'package:soundsense/core/database/sonic_database.dart';
import 'package:soundsense/core/ml/embedding_engine.dart';
import 'package:soundsense/core/ml/sound_classifier.dart';
import 'package:soundsense/core/providers/app_providers.dart';

import 'package:soundsense/core/ml/sound_labels.dart';

class TestVibrationService extends VibrationService {
  int triggerCount = 0;
  List<int>? lastPattern;

  @override
  Future<void> init() async {}

  @override
  Future<void> triggerPersonalSoundVibration() async {
    triggerCount++;
    lastPattern = SoundCategories.personalSoundVibrationPattern;
  }

  @override
  Future<void> triggerVibrationForCategory(String categoryKey) async {
    triggerCount++;
    lastPattern = SoundCategories.getByKey(categoryKey).vibrationPattern;
  }

  @override
  Future<void> triggerPattern(List<int> pattern) async {
    triggerCount++;
    lastPattern = pattern;
  }
}

class TestNotificationService extends NotificationService {
  int notificationCount = 0;
  String? lastTitle;

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> showSoundAlert({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    notificationCount++;
    lastTitle = title;
  }
}

class TestAudioRecorderService extends AudioRecorderService {
  @override
  Future<bool> startListening({bool simulation = false}) async {
    return true;
  }

  @override
  Future<void> stopListening() async {}
}

class TestBleService extends BleService {
  @override
  Future<void> startScan() async {}

  @override
  Future<void> stopScan() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SonicDatabase db;
  late TestAudioRecorderService audioService;
  late SoundClassifier classifier;
  late TestVibrationService vibService;
  late TestNotificationService notifService;
  late AlertService alertService;
  late TestBleService bleService;

  setUp(() {
    db = SonicDatabase.inMemory();
    audioService = TestAudioRecorderService();
    classifier = SoundClassifier();
    vibService = TestVibrationService();
    notifService = TestNotificationService();
    bleService = TestBleService();
    alertService = AlertService(
      vibrationService: vibService,
      notificationService: notifService,
      database: db,
    );
  });

  tearDown(() {
    alertService.dispose();
    audioService.dispose();
    classifier.dispose();
    bleService.dispose();
    db.dispose();
  });

  testWidgets(
    'FULL PASS: Onboarding -> Permissions -> Teach Sound -> Alert & Vibrate -> History -> 3x Thumbs-Down Auto-Raise Threshold',
    (WidgetTester tester) async {
      // -------------------------------------------------------------
      // 1. ONBOARDING FLOW
      // -------------------------------------------------------------
      debugPrint('[TEST] Step 1: Pump widget');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            audioRecorderServiceProvider.overrideWithValue(audioService),
            alertServiceProvider.overrideWithValue(alertService),
            soundClassifierProvider.overrideWithValue(classifier),
            vibrationServiceProvider.overrideWithValue(vibService),
            notificationServiceProvider.overrideWithValue(notifService),
            bleServiceProvider.overrideWithValue(bleService),
          ],
          child: const SonicApp(),
        ),
      );
      await tester.pumpAndSettle();

      debugPrint('[TEST] Step 2: Onboarding screens');
      // Screen 1: Sound awareness
      expect(find.text('Sound Awareness for Everyone'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Screen 2: Teach Sonic
      expect(find.text('Teach Sonic Your World'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Screen 3: Wearable alerts
      expect(find.text('Wearable Tactile Alerts'), findsOneWidget);
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      debugPrint('[TEST] Step 3: Permissions screen');
      // -------------------------------------------------------------
      // 2. PERMISSIONS SCREEN
      // -------------------------------------------------------------
      expect(find.text('Permissions Required'), findsOneWidget);
      expect(find.text('Microphone Access'), findsOneWidget);
      expect(find.text('Notification Access'), findsOneWidget);

      // Tap continue to enter main app
      final continueBtn = find.textContaining('Continue');
      expect(continueBtn, findsOneWidget);
      await tester.tap(continueBtn);
      debugPrint('[TEST] Step 4: Tapped Continue, pumping');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      debugPrint('[TEST] Step 5: On Home screen');
      // -------------------------------------------------------------
      // 3. HOME SCREEN ACTIVE
      // -------------------------------------------------------------
      expect(find.text('● LISTENING FOR CRITICAL SOUNDS'), findsOneWidget);

      // -------------------------------------------------------------
      // 4. TEACH A SOUND FLOW & EMBEDDING EXTRACTION
      // -------------------------------------------------------------
      debugPrint('[TEST] Step 6: Prototype averaging');
      // User creates "My Doorbell" with 3 samples
      final sample1 = List<double>.filled(128, 0.4);
      final sample2 = List<double>.filled(128, 0.42);
      final sample3 = List<double>.filled(128, 0.38);

      final prototypeVector = EmbeddingEngine.averagePrototypes([
        sample1,
        sample2,
        sample3,
      ]);
      expect(prototypeVector.length, equals(128));

      // Verify L2 unit vector property
      double sumSquares = 0.0;
      for (final val in prototypeVector) {
        sumSquares += val * val;
      }
      expect(sumSquares, closeTo(1.0, 1e-4));

      // Persist prototype to Drift SQLite
      final taughtSound = TaughtSound(
        id: 'user-doorbell-001',
        name: 'My Doorbell',
        iconCode: Icons.doorbell.codePoint,
        colorValue: 0xFF00F0FF,
        embeddingJson: jsonEncode(prototypeVector),
        sampleCount: 3,
        threshold: 0.85,
        consecutiveThumbsDown: 0,
        createdAt: DateTime.now(),
        isEnabled: true,
      );
      await db.insertTaughtSound(taughtSound);

      final saved = await db.getTaughtSoundById('user-doorbell-001');
      expect(saved, isNotNull);
      expect(saved!.name, equals('My Doorbell'));
      expect(saved.threshold, equals(0.85));

      debugPrint('[TEST] Step 7: Few-shot matching & alert trigger');
      // -------------------------------------------------------------
      // 5. FEW-SHOT MATCHING & ALERT TRIGGERING (< 2 seconds)
      // -------------------------------------------------------------
      final stopwatch = Stopwatch()..start();

      // Simulated incoming live audio embedding matching the prototype
      final liveMatchingEmbedding = List<double>.filled(128, 0.40);
      final normalizedLive = EmbeddingEngine.l2Normalize(liveMatchingEmbedding);

      final matches = EmbeddingEngine.matchLiveEmbedding(
        liveEmbedding: normalizedLive,
        prototypes: [saved],
      );
      expect(matches.isNotEmpty, isTrue);
      expect(matches.first.isTriggered, isTrue);
      expect(matches.first.similarity, greaterThanOrEqualTo(0.85));

      // Trigger alert via AlertService
      final alertFired = await alertService.triggerAlert(
        soundKey: saved.id,
        soundName: saved.name,
        category: 'PERSONAL',
        confidence: matches.first.similarity,
        isPersonal: true,
        prototypeId: saved.id,
      );
      stopwatch.stop();

      expect(alertFired, isTrue);
      expect(stopwatch.elapsedMilliseconds, lessThan(2000)); // Within 2 seconds!
      expect(vibService.triggerCount, equals(1));
      expect(notifService.notificationCount, equals(1));
      expect(notifService.lastTitle, contains('My Doorbell'));

      alertService.dismissBanner();
      await tester.pump(const Duration(milliseconds: 100));

      debugPrint('[TEST] Step 8: Debounce verification');
      // -------------------------------------------------------------
      // 6. 10-SECOND DEBOUNCING VERIFICATION
      // -------------------------------------------------------------
      // Immediate duplicate trigger must be debounced
      final duplicateAlertFired = await alertService.triggerAlert(
        soundKey: saved.id,
        soundName: saved.name,
        category: 'PERSONAL',
        confidence: matches.first.similarity,
        isPersonal: true,
        prototypeId: saved.id,
      );
      expect(duplicateAlertFired, isFalse);
      expect(vibService.triggerCount, equals(1)); // Remained 1!
      expect(notifService.notificationCount, equals(1)); // Remained 1!

      debugPrint('[TEST] Step 9: History & Thumbs-Down verification');

      // -------------------------------------------------------------
      // 7. ALERT LOGGED IN DRIFT HISTORY
      // -------------------------------------------------------------
      final history = await db.getAlertHistory();
      expect(history.length, equals(1));
      final loggedAlert = history.first;
      expect(loggedAlert.soundName, equals('My Doorbell'));
      expect(loggedAlert.isPersonal, isTrue);
      expect(loggedAlert.prototypeId, equals('user-doorbell-001'));
      expect(loggedAlert.feedback, equals(0)); // Unrated

      // -------------------------------------------------------------
      // 8. 3 CONSECUTIVE THUMBS-DOWN AUTOMATICALLY RAISES THRESHOLD
      // -------------------------------------------------------------
      // Feedback 1: Thumbs-down
      await db.updateAlertFeedback(loggedAlert.id, -1);
      final raise1 = await db.recordThumbsDownForPrototype(saved.id);
      expect(raise1, isNull);
      var currentProto = await db.getTaughtSoundById(saved.id);
      expect(currentProto!.consecutiveThumbsDown, equals(1));
      expect(currentProto.threshold, equals(0.85));

      // Feedback 2: Thumbs-down
      final raise2 = await db.recordThumbsDownForPrototype(saved.id);
      expect(raise2, isNull);
      currentProto = await db.getTaughtSoundById(saved.id);
      expect(currentProto!.consecutiveThumbsDown, equals(2));
      expect(currentProto.threshold, equals(0.85));

      // Feedback 3: Thumbs-down -> AUTOMATIC ELEVATION TO 0.89!
      final newThreshold = await db.recordThumbsDownForPrototype(saved.id);
      expect(newThreshold, isNotNull);
      expect(newThreshold!, closeTo(0.89, 1e-4));

      // Verify database reflects new sensitivity threshold and resets counter
      currentProto = await db.getTaughtSoundById(saved.id);
      expect(currentProto!.threshold, closeTo(0.89, 1e-4));
      expect(currentProto.consecutiveThumbsDown, equals(0));

      // Cleanly unmount widget tree to cancel tickers & animations
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await audioService.stopListening();
    },
  );
}
