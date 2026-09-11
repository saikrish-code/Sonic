import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundsense/core/database/sonic_database.dart';

void main() {
  late SonicDatabase db;

  setUp(() {
    db = SonicDatabase.inMemory();
  });

  tearDown(() {
    db.dispose();
  });

  group('SonicDatabase Tests', () {
    test('Can insert and retrieve taught sound', () async {
      final embedding = List<double>.generate(128, (i) => i / 128.0);
      final sound = TaughtSound(
        id: 'test-sound-1',
        name: 'Front Doorbell',
        iconCode: 0xe000,
        colorValue: 0xFF00F0FF,
        embeddingJson: jsonEncode(embedding),
        sampleCount: 3,
        threshold: 0.85,
        createdAt: DateTime.now(),
      );

      await db.insertTaughtSound(sound);
      final retrieved = await db.getTaughtSoundById('test-sound-1');

      expect(retrieved, isNotNull);
      expect(retrieved!.name, equals('Front Doorbell'));
      expect(retrieved.threshold, equals(0.85));
      expect(retrieved.embeddingVector.length, equals(128));
      expect(retrieved.embeddingVector[0], closeTo(0.0, 1e-4));
    });

    test('3 consecutive thumbs-down automatically raises prototype threshold', () async {
      final embedding = List<double>.generate(128, (i) => 0.1);
      final sound = TaughtSound(
        id: 'prototype-doorbell',
        name: 'My Doorbell',
        iconCode: 0xe001,
        colorValue: 0xFFFFB703,
        embeddingJson: jsonEncode(embedding),
        sampleCount: 3,
        threshold: 0.85,
        createdAt: DateTime.now(),
      );

      await db.insertTaughtSound(sound);

      // First thumbs down -> no threshold raise yet
      final result1 = await db.recordThumbsDownForPrototype('prototype-doorbell');
      expect(result1, isNull);
      var current = await db.getTaughtSoundById('prototype-doorbell');
      expect(current!.consecutiveThumbsDown, equals(1));
      expect(current.threshold, equals(0.85));

      // Second thumbs down -> no threshold raise yet
      final result2 = await db.recordThumbsDownForPrototype('prototype-doorbell');
      expect(result2, isNull);
      current = await db.getTaughtSoundById('prototype-doorbell');
      expect(current!.consecutiveThumbsDown, equals(2));
      expect(current.threshold, equals(0.85));

      // Third thumbs down -> AUTOMATIC THRESHOLD RAISE (+0.04 -> 0.89)
      final result3 = await db.recordThumbsDownForPrototype('prototype-doorbell');
      expect(result3, isNotNull);
      expect(result3!, closeTo(0.89, 1e-4));

      current = await db.getTaughtSoundById('prototype-doorbell');
      expect(current!.threshold, closeTo(0.89, 1e-4));
      expect(current.consecutiveThumbsDown, equals(0)); // Reset to 0
    });

    test('Thumbs-up resets consecutive thumbs-down counter', () async {
      final sound = TaughtSound(
        id: 'prototype-siren',
        name: 'Car Horn',
        iconCode: 0xe002,
        colorValue: 0xFFFF2A6D,
        embeddingJson: jsonEncode(List<double>.filled(128, 0.5)),
        createdAt: DateTime.now(),
      );

      await db.insertTaughtSound(sound);
      await db.recordThumbsDownForPrototype('prototype-siren');
      await db.recordThumbsDownForPrototype('prototype-siren');

      var current = await db.getTaughtSoundById('prototype-siren');
      expect(current!.consecutiveThumbsDown, equals(2));

      // Thumbs up resets to 0
      await db.recordThumbsUpForPrototype('prototype-siren');
      current = await db.getTaughtSoundById('prototype-siren');
      expect(current!.consecutiveThumbsDown, equals(0));
      expect(current.threshold, equals(0.85));
    });

    test('Alert history logs and updates feedback', () async {
      final alert = AlertHistoryData(
        id: 'alert-1',
        soundName: 'Smoke Alarm',
        category: 'Danger',
        confidence: 0.96,
        timestamp: DateTime.now(),
      );

      await db.insertAlert(alert);
      var history = await db.getAlertHistory();
      expect(history.length, equals(1));
      expect(history.first.soundName, equals('Smoke Alarm'));
      expect(history.first.feedback, equals(0));

      // User gives thumbs up (+1)
      await db.updateAlertFeedback('alert-1', 1);
      history = await db.getAlertHistory();
      expect(history.first.feedback, equals(1));
    });
  });
}
