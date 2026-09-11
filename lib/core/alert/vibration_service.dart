import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';
import '../ml/sound_labels.dart';

/// Service managing tactile haptic feedback and category vibration patterns.
class VibrationService {
  bool _hasVibrator = false;
  bool _hasCustomVibrations = false;
  bool _isInitialized = false;

  bool get hasVibrator => _hasVibrator;
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final hasVib = await Vibration.hasVibrator();
      _hasVibrator = hasVib == true;
      final hasCustom = await Vibration.hasCustomVibrationsSupport();
      _hasCustomVibrations = hasCustom == true;
    } catch (e) {
      debugPrint('[SonicVibe] Failed to query vibrator support: $e');
      _hasVibrator = false;
    }
    _isInitialized = true;
  }

  /// Triggers vibration pattern for a given sound category or custom taught sound.
  Future<void> triggerVibrationForCategory(String categoryKey) async {
    final cat = SoundCategories.getByKey(categoryKey);
    await triggerPattern(cat.vibrationPattern);
  }

  /// Triggers vibration pattern for personal sound.
  Future<void> triggerPersonalSoundVibration() async {
    await triggerPattern(SoundCategories.personalSoundVibrationPattern);
  }

  /// Triggers an explicit vibration pattern list [wait, vibrate, wait, vibrate...].
  Future<void> triggerPattern(List<int> pattern) async {
    try {
      if (!_isInitialized) await init();
      if (!_hasVibrator) return;

      if (_hasCustomVibrations) {
        await Vibration.vibrate(pattern: pattern);
      } else {
        // Fallback simple vibration
        await Vibration.vibrate(duration: 500);
      }
    } catch (e) {
      debugPrint('[SonicVibe] Vibration trigger failed: $e');
    }
  }

  /// Cancel current ongoing vibration.
  Future<void> cancel() async {
    try {
      await Vibration.cancel();
    } catch (_) {}
  }
}
