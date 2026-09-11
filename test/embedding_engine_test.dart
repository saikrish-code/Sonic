import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundsense/core/database/sonic_database.dart';
import 'package:soundsense/core/ml/embedding_engine.dart';

void main() {
  group('EmbeddingEngine Tests', () {
    test('l2Normalize produces unit vector', () {
      final v = [3.0, 4.0];
      final norm = EmbeddingEngine.l2Normalize(v);
      expect(norm[0], closeTo(0.6, 1e-4));
      expect(norm[1], closeTo(0.8, 1e-4));

      final len = norm[0] * norm[0] + norm[1] * norm[1];
      expect(len, closeTo(1.0, 1e-4));
    });

    test('cosineSimilarity of identical vectors is 1.0, orthogonal is 0.0', () {
      final a = [1.0, 0.0, 0.0];
      final b = [1.0, 0.0, 0.0];
      final c = [0.0, 1.0, 0.0];

      expect(EmbeddingEngine.cosineSimilarity(a, b), closeTo(1.0, 1e-4));
      expect(EmbeddingEngine.cosineSimilarity(a, c), closeTo(0.0, 1e-4));
    });

    test('averagePrototypes correctly computes mean of multiple samples and normalizes', () {
      final s1 = [1.0, 0.0];
      final s2 = [0.0, 1.0];

      // Mean: [0.5, 0.5] -> L2 normalized: [1/sqrt(2), 1/sqrt(2)]
      final avg = EmbeddingEngine.averagePrototypes([s1, s2]);
      expect(avg[0], closeTo(0.7071, 1e-3));
      expect(avg[1], closeTo(0.7071, 1e-3));
    });

    test('matchLiveEmbedding filters by prototype threshold', () {
      // Prototype 1 has high similarity, Prototype 2 has low similarity
      final liveVec = EmbeddingEngine.l2Normalize([1.0, 1.0, 0.0]);

      final p1Vec = EmbeddingEngine.l2Normalize([1.0, 0.9, 0.0]); // very similar
      final p2Vec = EmbeddingEngine.l2Normalize([0.0, 0.0, 1.0]); // orthogonal

      final p1 = TaughtSound(
        id: 'p1',
        name: 'Doorbell',
        iconCode: 1,
        colorValue: 1,
        embeddingJson: jsonEncode(p1Vec),
        threshold: 0.85,
        createdAt: DateTime.now(),
      );

      final p2 = TaughtSound(
        id: 'p2',
        name: 'Alarm',
        iconCode: 2,
        colorValue: 2,
        embeddingJson: jsonEncode(p2Vec),
        threshold: 0.85,
        createdAt: DateTime.now(),
      );

      final matches = EmbeddingEngine.matchLiveEmbedding(
        liveEmbedding: liveVec,
        prototypes: [p1, p2],
      );

      expect(matches.length, equals(2));
      expect(matches.first.sound.id, equals('p1'));
      expect(matches.first.similarity, greaterThan(0.85));
      expect(matches.first.isTriggered, isTrue);

      expect(matches[1].sound.id, equals('p2'));
      expect(matches[1].similarity, lessThan(0.5));
      expect(matches[1].isTriggered, isFalse);
    });
  });
}
