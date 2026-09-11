import 'package:flutter_test/flutter_test.dart';
import 'package:soundsense/core/alert/alert_service.dart';
import 'package:soundsense/core/alert/notification_service.dart';
import 'package:soundsense/core/alert/vibration_service.dart';
import 'package:soundsense/core/database/sonic_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SonicDatabase db;
  late VibrationService vibService;
  late NotificationService notifService;
  late AlertService alertService;

  setUp(() {
    db = SonicDatabase.inMemory();
    vibService = VibrationService();
    notifService = NotificationService();
    alertService = AlertService(
      vibrationService: vibService,
      notificationService: notifService,
      database: db,
    );
  });

  tearDown(() {
    alertService.dispose();
    db.dispose();
  });

  group('AlertService Debounce Tests', () {
    test('First alert triggers, immediate second trigger of same sound is debounced', () async {
      final fired1 = await alertService.triggerAlert(
        soundKey: 'doorbell',
        soundName: 'Doorbell',
        category: 'Warning',
        confidence: 0.90,
      );
      expect(fired1, isTrue);

      // Immediate second trigger within 10s window must be debounced
      final fired2 = await alertService.triggerAlert(
        soundKey: 'doorbell',
        soundName: 'Doorbell',
        category: 'Warning',
        confidence: 0.92,
      );
      expect(fired2, isFalse);

      // Different sound triggers independently
      final fired3 = await alertService.triggerAlert(
        soundKey: 'smoke_alarm',
        soundName: 'Smoke Alarm',
        category: 'Danger',
        confidence: 0.95,
      );
      expect(fired3, isTrue);

      // Verify database recorded exactly 2 alerts (doorbell + smoke alarm), not 3
      final history = await db.getAlertHistory();
      expect(history.length, equals(2));
    });

    test('Alert re-triggers after debounce history is cleared', () async {
      final fired1 = await alertService.triggerAlert(
        soundKey: 'dog_bark',
        soundName: 'Dog Bark',
        category: 'Warning',
        confidence: 0.88,
      );
      expect(fired1, isTrue);

      alertService.clearDebounceHistory();

      final fired2 = await alertService.triggerAlert(
        soundKey: 'dog_bark',
        soundName: 'Dog Bark',
        category: 'Warning',
        confidence: 0.89,
      );
      expect(fired2, isTrue);

      final history = await db.getAlertHistory();
      expect(history.length, equals(2));
    });
  });
}
