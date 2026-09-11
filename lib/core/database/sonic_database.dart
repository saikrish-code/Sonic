import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import '../constants/app_constants.dart';

/// Represents a user-taught custom sound prototype.
class TaughtSound {
  final String id;
  final String name;
  final int iconCode;
  final int colorValue;
  final String embeddingJson;
  final int sampleCount;
  final double threshold;
  final int consecutiveThumbsDown;
  final DateTime createdAt;
  final bool isEnabled;

  const TaughtSound({
    required this.id,
    required this.name,
    required this.iconCode,
    required this.colorValue,
    required this.embeddingJson,
    this.sampleCount = 3,
    this.threshold = AppConstants.defaultSimilarityThreshold,
    this.consecutiveThumbsDown = 0,
    required this.createdAt,
    this.isEnabled = true,
  });

  /// Decodes the 128-dimensional embedding vector from JSON
  List<double> get embeddingVector {
    try {
      final List<dynamic> decoded = jsonDecode(embeddingJson) as List<dynamic>;
      return decoded.map((e) => (e as num).toDouble()).toList();
    } catch (_) {
      return List<double>.filled(AppConstants.embeddingDimension, 0.0);
    }
  }

  TaughtSound copyWith({
    String? id,
    String? name,
    int? iconCode,
    int? colorValue,
    String? embeddingJson,
    int? sampleCount,
    double? threshold,
    int? consecutiveThumbsDown,
    DateTime? createdAt,
    bool? isEnabled,
  }) {
    return TaughtSound(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCode: iconCode ?? this.iconCode,
      colorValue: colorValue ?? this.colorValue,
      embeddingJson: embeddingJson ?? this.embeddingJson,
      sampleCount: sampleCount ?? this.sampleCount,
      threshold: threshold ?? this.threshold,
      consecutiveThumbsDown:
          consecutiveThumbsDown ?? this.consecutiveThumbsDown,
      createdAt: createdAt ?? this.createdAt,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon_code': iconCode,
      'color_value': colorValue,
      'embedding_json': embeddingJson,
      'sample_count': sampleCount,
      'threshold': threshold,
      'consecutive_thumbs_down': consecutiveThumbsDown,
      'created_at': createdAt.toIso8601String(),
      'is_enabled': isEnabled ? 1 : 0,
    };
  }

  factory TaughtSound.fromRow(Row row) {
    return TaughtSound(
      id: row['id'] as String,
      name: row['name'] as String,
      iconCode: row['icon_code'] as int,
      colorValue: row['color_value'] as int,
      embeddingJson: row['embedding_json'] as String,
      sampleCount: row['sample_count'] as int,
      threshold: (row['threshold'] as num).toDouble(),
      consecutiveThumbsDown: row['consecutive_thumbs_down'] as int,
      createdAt: DateTime.parse(row['created_at'] as String),
      isEnabled: (row['is_enabled'] as int) == 1,
    );
  }
}

/// Represents an alert record in the history log.
class AlertHistoryData {
  final String id;
  final String soundName;
  final String category;
  final bool isPersonal;
  final String? prototypeId;
  final double confidence;
  final DateTime timestamp;
  final int feedback; // 0 = unrated, 1 = thumbs up, -1 = thumbs down

  const AlertHistoryData({
    required this.id,
    required this.soundName,
    required this.category,
    this.isPersonal = false,
    this.prototypeId,
    required this.confidence,
    required this.timestamp,
    this.feedback = 0,
  });

  AlertHistoryData copyWith({
    String? id,
    String? soundName,
    String? category,
    bool? isPersonal,
    String? prototypeId,
    double? confidence,
    DateTime? timestamp,
    int? feedback,
  }) {
    return AlertHistoryData(
      id: id ?? this.id,
      soundName: soundName ?? this.soundName,
      category: category ?? this.category,
      isPersonal: isPersonal ?? this.isPersonal,
      prototypeId: prototypeId ?? this.prototypeId,
      confidence: confidence ?? this.confidence,
      timestamp: timestamp ?? this.timestamp,
      feedback: feedback ?? this.feedback,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sound_name': soundName,
      'category': category,
      'is_personal': isPersonal ? 1 : 0,
      'prototype_id': prototypeId,
      'confidence': confidence,
      'timestamp': timestamp.toIso8601String(),
      'feedback': feedback,
    };
  }

  factory AlertHistoryData.fromRow(Row row) {
    return AlertHistoryData(
      id: row['id'] as String,
      soundName: row['sound_name'] as String,
      category: row['category'] as String,
      isPersonal: (row['is_personal'] as int) == 1,
      prototypeId: row['prototype_id'] as String?,
      confidence: (row['confidence'] as num).toDouble(),
      timestamp: DateTime.parse(row['timestamp'] as String),
      feedback: row['feedback'] as int,
    );
  }
}

/// Database service powering local SQLite persistence with reactive streams.
class SonicDatabase {
  final Database _db;
  final StreamController<List<TaughtSound>> _taughtSoundsController =
      StreamController<List<TaughtSound>>.broadcast();
  final StreamController<List<AlertHistoryData>> _alertHistoryController =
      StreamController<List<AlertHistoryData>>.broadcast();

  SonicDatabase(this._db) {
    _createTables();
  }

  /// Factory creating an on-device persistent database instance.
  static Future<SonicDatabase> open({String dbName = 'sonic_local.db'}) async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final path = p.join(docDir.path, dbName);
      final rawDb = sqlite3.open(path);
      return SonicDatabase(rawDb);
    } catch (e) {
      debugPrint('[SonicDB] Failed to open file database ($e), using in-memory database');
      return SonicDatabase(sqlite3.openInMemory());
    }
  }

  /// Factory creating an in-memory database for testing.
  factory SonicDatabase.inMemory() {
    return SonicDatabase(sqlite3.openInMemory());
  }

  void _createTables() {
    _db.execute('''
      CREATE TABLE IF NOT EXISTS taught_sounds (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon_code INTEGER NOT NULL,
        color_value INTEGER NOT NULL,
        embedding_json TEXT NOT NULL,
        sample_count INTEGER NOT NULL DEFAULT 3,
        threshold REAL NOT NULL DEFAULT 0.85,
        consecutive_thumbs_down INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        is_enabled INTEGER NOT NULL DEFAULT 1
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS alert_history (
        id TEXT PRIMARY KEY,
        sound_name TEXT NOT NULL,
        category TEXT NOT NULL,
        is_personal INTEGER NOT NULL DEFAULT 0,
        prototype_id TEXT,
        confidence REAL NOT NULL,
        timestamp TEXT NOT NULL,
        feedback INTEGER NOT NULL DEFAULT 0
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS category_settings (
        category_key TEXT PRIMARY KEY,
        threshold REAL NOT NULL DEFAULT 0.70,
        is_enabled INTEGER NOT NULL DEFAULT 1
      );
    ''');
  }

  // --- TAUGHT SOUNDS OPERATIONS ---

  Stream<List<TaughtSound>> watchAllTaughtSounds() {
    // Prime the stream with current data
    Future.microtask(() => _notifyTaughtSounds());
    return _taughtSoundsController.stream;
  }

  Future<List<TaughtSound>> getAllTaughtSounds() async {
    final results = _db.select(
      'SELECT * FROM taught_sounds ORDER BY created_at DESC',
    );
    return results.map(TaughtSound.fromRow).toList();
  }

  Future<TaughtSound?> getTaughtSoundById(String id) async {
    final results = _db.select(
      'SELECT * FROM taught_sounds WHERE id = ?',
      [id],
    );
    if (results.isEmpty) return null;
    return TaughtSound.fromRow(results.first);
  }

  Future<void> insertTaughtSound(TaughtSound sound) async {
    _db.execute('''
      INSERT INTO taught_sounds (
        id, name, icon_code, color_value, embedding_json,
        sample_count, threshold, consecutive_thumbs_down, created_at, is_enabled
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', [
      sound.id,
      sound.name,
      sound.iconCode,
      sound.colorValue,
      sound.embeddingJson,
      sound.sampleCount,
      sound.threshold,
      sound.consecutiveThumbsDown,
      sound.createdAt.toIso8601String(),
      sound.isEnabled ? 1 : 0,
    ]);
    _notifyTaughtSounds();
  }

  Future<void> updateTaughtSound(TaughtSound sound) async {
    _db.execute('''
      UPDATE taught_sounds SET
        name = ?, icon_code = ?, color_value = ?,
        embedding_json = ?, sample_count = ?, threshold = ?,
        consecutive_thumbs_down = ?, is_enabled = ?
      WHERE id = ?
    ''', [
      sound.name,
      sound.iconCode,
      sound.colorValue,
      sound.embeddingJson,
      sound.sampleCount,
      sound.threshold,
      sound.consecutiveThumbsDown,
      sound.isEnabled ? 1 : 0,
      sound.id,
    ]);
    _notifyTaughtSounds();
  }

  Future<void> updateTaughtSoundThreshold(String id, double newThreshold) async {
    final clamped = newThreshold.clamp(
      AppConstants.minSensitivityThreshold,
      AppConstants.maxSensitivityThreshold,
    );
    _db.execute(
      'UPDATE taught_sounds SET threshold = ? WHERE id = ?',
      [clamped, id],
    );
    _notifyTaughtSounds();
  }

  Future<void> updateTaughtSoundDetails({
    required String id,
    required String name,
    required int iconCode,
    required int colorValue,
    required double threshold,
  }) async {
    _db.execute('''
      UPDATE taught_sounds SET
        name = ?, icon_code = ?, color_value = ?, threshold = ?
      WHERE id = ?
    ''', [name, iconCode, colorValue, threshold, id]);
    _notifyTaughtSounds();
  }

  /// Increments consecutive thumbs-down count.
  /// If it reaches 3, automatically raises the prototype's threshold by 0.04
  /// and resets the counter. Returns the new threshold if raised, or null if not.
  Future<double?> recordThumbsDownForPrototype(String prototypeId) async {
    final sound = await getTaughtSoundById(prototypeId);
    if (sound == null) return null;

    final newCount = sound.consecutiveThumbsDown + 1;
    if (newCount >= AppConstants.maxConsecutiveThumbsDown) {
      final newThreshold = (sound.threshold + AppConstants.thresholdAdjustmentStep)
          .clamp(AppConstants.minSensitivityThreshold, AppConstants.maxSensitivityThreshold);

      _db.execute('''
        UPDATE taught_sounds
        SET threshold = ?, consecutive_thumbs_down = 0
        WHERE id = ?
      ''', [newThreshold, prototypeId]);

      _notifyTaughtSounds();
      return newThreshold;
    } else {
      _db.execute(
        'UPDATE taught_sounds SET consecutive_thumbs_down = ? WHERE id = ?',
        [newCount, prototypeId],
      );
      _notifyTaughtSounds();
      return null;
    }
  }

  Future<void> recordThumbsUpForPrototype(String prototypeId) async {
    _db.execute(
      'UPDATE taught_sounds SET consecutive_thumbs_down = 0 WHERE id = ?',
      [prototypeId],
    );
    _notifyTaughtSounds();
  }

  Future<void> deleteTaughtSound(String id) async {
    _db.execute('DELETE FROM taught_sounds WHERE id = ?', [id]);
    _notifyTaughtSounds();
  }

  void _notifyTaughtSounds() async {
    if (!_taughtSoundsController.isClosed) {
      final list = await getAllTaughtSounds();
      _taughtSoundsController.add(list);
    }
  }

  // --- ALERT HISTORY OPERATIONS ---

  Stream<List<AlertHistoryData>> watchAlertHistory({int limit = 100}) {
    Future.microtask(() => _notifyAlertHistory(limit));
    return _alertHistoryController.stream;
  }

  Future<List<AlertHistoryData>> getAlertHistory({int limit = 100}) async {
    final results = _db.select(
      'SELECT * FROM alert_history ORDER BY timestamp DESC LIMIT ?',
      [limit],
    );
    return results.map(AlertHistoryData.fromRow).toList();
  }

  Future<void> insertAlert(AlertHistoryData alert) async {
    _db.execute('''
      INSERT INTO alert_history (
        id, sound_name, category, is_personal, prototype_id,
        confidence, timestamp, feedback
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ''', [
      alert.id,
      alert.soundName,
      alert.category,
      alert.isPersonal ? 1 : 0,
      alert.prototypeId,
      alert.confidence,
      alert.timestamp.toIso8601String(),
      alert.feedback,
    ]);
    _notifyAlertHistory(100);
  }

  Future<void> updateAlertFeedback(String id, int feedback) async {
    _db.execute(
      'UPDATE alert_history SET feedback = ? WHERE id = ?',
      [feedback, id],
    );
    _notifyAlertHistory(100);
  }

  Future<void> clearAlertHistory() async {
    _db.execute('DELETE FROM alert_history');
    _notifyAlertHistory(100);
  }

  void _notifyAlertHistory(int limit) async {
    if (!_alertHistoryController.isClosed) {
      final list = await getAlertHistory(limit: limit);
      _alertHistoryController.add(list);
    }
  }

  // --- CATEGORY SENSITIVITY SETTINGS ---

  Future<void> setCategorySensitivity(String categoryKey, double threshold) async {
    _db.execute('''
      INSERT INTO category_settings (category_key, threshold, is_enabled)
      VALUES (?, ?, 1)
      ON CONFLICT(category_key) DO UPDATE SET threshold = excluded.threshold
    ''', [categoryKey, threshold]);
  }

  Future<Map<String, double>> getAllCategorySensitivities() async {
    final results = _db.select('SELECT category_key, threshold FROM category_settings');
    final map = <String, double>{};
    for (final row in results) {
      map[row['category_key'] as String] = (row['threshold'] as num).toDouble();
    }
    return map;
  }

  void dispose() {
    _taughtSoundsController.close();
    _alertHistoryController.close();
    _db.dispose();
  }
}
