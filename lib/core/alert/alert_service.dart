import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_constants.dart';
import '../database/sonic_database.dart';
import '../theme/sonic_colors.dart';
import 'notification_service.dart';
import 'vibration_service.dart';

/// Represents an active visual alert banner for accessible in-app heads-up display.
class ActiveAlertBanner {
  final String id;
  final String soundName;
  final String category;
  final double confidence;
  final bool isPersonal;
  final Color color;
  final IconData icon;
  final DateTime timestamp;

  const ActiveAlertBanner({
    required this.id,
    required this.soundName,
    required this.category,
    required this.confidence,
    required this.isPersonal,
    required this.color,
    required this.icon,
    required this.timestamp,
  });
}

/// Central alert coordinator handling debouncing, vibration patterns,
/// local notifications, and accessible visual alert strobe overlays.
class AlertService {
  final VibrationService vibrationService;
  final NotificationService notificationService;
  final SonicDatabase database;

  // Debounce tracker: soundKey -> last triggered timestamp
  final Map<String, DateTime> _lastAlertTimes = {};

  final StreamController<ActiveAlertBanner?> _activeBannerController =
      StreamController<ActiveAlertBanner?>.broadcast();
  Stream<ActiveAlertBanner?> get activeBannerStream => _activeBannerController.stream;

  Timer? _bannerDismissTimer;

  AlertService({
    required this.vibrationService,
    required this.notificationService,
    required this.database,
  });

  /// Returns true if the sound is currently in a debounce cooldown window.
  bool isDebounced(String soundKey) {
    if (!_lastAlertTimes.containsKey(soundKey)) return false;
    final elapsed = DateTime.now().difference(_lastAlertTimes[soundKey]!);
    return elapsed.inSeconds < AppConstants.debounceDurationSeconds;
  }

  /// Triggers a sound alert if not debounced.
  /// Returns `true` if alert was triggered, `false` if suppressed by debounce.
  Future<bool> triggerAlert({
    required String soundKey,
    required String soundName,
    required String category,
    required double confidence,
    bool isPersonal = false,
    String? prototypeId,
    Color color = SonicColors.alertAmber,
    IconData icon = Icons.notifications_active,
  }) async {
    final now = DateTime.now();

    // 1. Debounce check (10 seconds cooldown per sound)
    if (isDebounced(soundKey)) {
      debugPrint('[SonicAlert] Suppressed alert for "$soundName" due to 10s debounce window');
      return false;
    }

    _lastAlertTimes[soundKey] = now;
    final alertId = const Uuid().v4();

    // 2. Trigger vibration pattern
    if (isPersonal) {
      await vibrationService.triggerPersonalSoundVibration();
    } else {
      await vibrationService.triggerVibrationForCategory(soundKey);
    }

    // 3. Fire Local Notification
    final notifId = soundKey.hashCode.abs() % 10000;
    final confPercent = (confidence * 100).toInt().clamp(0, 100);
    await notificationService.showSoundAlert(
      id: notifId,
      title: '🚨 Sound Alert: $soundName',
      body: 'Detected with $confPercent% confidence',
      payload: alertId,
    );

    // 4. Log alert to local SQLite database
    final alertRecord = AlertHistoryData(
      id: alertId,
      soundName: soundName,
      category: category,
      isPersonal: isPersonal,
      prototypeId: prototypeId,
      confidence: confidence,
      timestamp: now,
    );
    await database.insertAlert(alertRecord);

    // 5. Emit in-app visual alert banner (accessible flash for Deaf users)
    final banner = ActiveAlertBanner(
      id: alertId,
      soundName: soundName,
      category: category,
      confidence: confidence,
      isPersonal: isPersonal,
      color: color,
      icon: icon,
      timestamp: now,
    );

    _activeBannerController.add(banner);

    // Auto-dismiss in-app banner after 4.5 seconds
    _bannerDismissTimer?.cancel();
    _bannerDismissTimer = Timer(const Duration(milliseconds: 4500), () {
      _activeBannerController.add(null);
    });

    return true;
  }

  void dismissBanner() {
    _bannerDismissTimer?.cancel();
    _activeBannerController.add(null);
  }

  /// Clears debounce history (useful for tests or immediate re-triggering)
  void clearDebounceHistory() {
    _lastAlertTimes.clear();
  }

  void dispose() {
    _bannerDismissTimer?.cancel();
    _activeBannerController.close();
  }
}
