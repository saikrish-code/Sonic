import 'dart:math' as math;
import '../database/sonic_database.dart';

/// Result of matching a live audio embedding against a user-taught prototype.
class PersonalSoundMatch {
  final TaughtSound sound;
  final double similarity;
  final bool isTriggered;

  const PersonalSoundMatch({
    required this.sound,
    required this.similarity,
    required this.isTriggered,
  });
}

/// Mathematical vector operations and few-shot matching engine.
class EmbeddingEngine {
  /// Normalizes vector [v] to unit length (L2 norm = 1.0).
  static List<double> l2Normalize(List<double> v) {
    double sumSquares = 0.0;
    for (int i = 0; i < v.length; i++) {
      sumSquares += v[i] * v[i];
    }

    final norm = math.sqrt(sumSquares);
    if (norm < 1e-12) {
      return List<double>.filled(v.length, 0.0);
    }

    final normalized = List<double>.filled(v.length, 0.0);
    for (int i = 0; i < v.length; i++) {
      normalized[i] = v[i] / norm;
    }
    return normalized;
  }

  /// Computes cosine similarity between two vectors [a] and [b].
  /// If both vectors are already L2 normalized, this equals the dot product.
  static double cosineSimilarity(List<double> a, List<double> b) {
    assert(a.length == b.length, 'Vectors must have identical dimensions');
    if (a.isEmpty || b.isEmpty) return 0.0;

    double dotProduct = 0.0;
    double normASq = 0.0;
    double normBSq = 0.0;

    for (int i = 0; i < a.length; i++) {
      final ai = a[i];
      final bi = b[i];
      dotProduct += ai * bi;
      normASq += ai * ai;
      normBSq += bi * bi;
    }

    final denom = math.sqrt(normASq) * math.sqrt(normBSq);
    if (denom < 1e-12) return 0.0;

    final sim = dotProduct / denom;
    return sim.clamp(-1.0, 1.0);
  }

  /// Averages multiple sample embedding vectors into a single representative prototype.
  /// The averaged vector is then L2-normalized.
  static List<double> averagePrototypes(List<List<double>> samples) {
    if (samples.isEmpty) return [];
    if (samples.length == 1) return l2Normalize(samples.first);

    final dim = samples.first.length;
    final averaged = List<double>.filled(dim, 0.0);

    for (final sample in samples) {
      assert(sample.length == dim, 'All samples must have the same dimension');
      for (int i = 0; i < dim; i++) {
        averaged[i] += sample[i];
      }
    }

    final numSamples = samples.length.toDouble();
    for (int i = 0; i < dim; i++) {
      averaged[i] /= numSamples;
    }

    return l2Normalize(averaged);
  }

  /// Evaluates a live embedding against all active user-taught prototypes.
  /// Returns matches sorted by highest similarity score.
  static List<PersonalSoundMatch> matchLiveEmbedding({
    required List<double> liveEmbedding,
    required List<TaughtSound> prototypes,
  }) {
    if (prototypes.isEmpty) return [];

    final matches = <PersonalSoundMatch>[];
    for (final proto in prototypes) {
      if (!proto.isEnabled) continue;

      final protoVec = proto.embeddingVector;
      final sim = cosineSimilarity(liveEmbedding, protoVec);
      final isTriggered = sim >= proto.threshold;

      matches.add(PersonalSoundMatch(
        sound: proto,
        similarity: sim,
        isTriggered: isTriggered,
      ));
    }

    // Sort descending by similarity
    matches.sort((a, b) => b.similarity.compareTo(a.similarity));
    return matches;
  }

  /// Computes a map of prototypeId -> similarity score for real-time debug visualizers.
  static Map<String, double> computeSimilarityGauges({
    required List<double> liveEmbedding,
    required List<TaughtSound> prototypes,
  }) {
    final map = <String, double>{};
    for (final proto in prototypes) {
      final sim = cosineSimilarity(liveEmbedding, proto.embeddingVector);
      map[proto.id] = (sim + 1.0) / 2.0; // Map [-1, 1] to [0, 1] for visual gauge
    }
    return map;
  }
}
