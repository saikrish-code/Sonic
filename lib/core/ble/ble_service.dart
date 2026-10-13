import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'ble_device_model.dart';

/// Service managing Bluetooth Low Energy scanning, simulated earpiece pairing,
/// and future GATT characteristic transmission.
class BleService {
  // Configured UUIDs for future Sonic Wearable Earpiece hardware
  static const String sonicServiceUuid = '0000FEAA-0000-1000-8000-00805F9B34FB';
  static const String hapticCharUuid = '0000FEAB-0000-1000-8000-00805F9B34FB';
  static const String batteryCharUuid = '00002A19-0000-1000-8000-00805F9B34FB';

  final StreamController<List<BleDeviceModel>> _scanResultsController =
      StreamController<List<BleDeviceModel>>.broadcast();
  Stream<List<BleDeviceModel>> get scanResultsStream => _scanResultsController.stream;

  final StreamController<BleDeviceModel?> _connectedDeviceController =
      StreamController<BleDeviceModel?>.broadcast();
  Stream<BleDeviceModel?> get connectedDeviceStream => _connectedDeviceController.stream;

  BleDeviceModel? _connectedDevice;
  BleDeviceModel? get connectedDevice => _connectedDevice;

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  StreamSubscription? _fbpSubscription;
  final List<BleDeviceModel> _discoveredDevices = [];

  /// Starts a real-time BLE scan for nearby peripherals. No demo devices
  /// are injected; the list only contains hardware actually discovered
  /// over Bluetooth (plus cached results refreshed on each scan).
  Future<void> startScan() async {
    if (_isScanning) return;
    _isScanning = true;
    _discoveredDevices.clear();
    _scanResultsController.add(List.unmodifiable(_discoveredDevices));

    try {
      final isSupported = await FlutterBluePlus.isSupported;
      if (isSupported) {
        await FlutterBluePlus.startScan(
          timeout: const Duration(seconds: 12),
          androidUsesFineLocation: true,
        );

        _fbpSubscription = FlutterBluePlus.scanResults.listen((results) {
          for (final r in results) {
            final name = r.advertisementData.advName.isNotEmpty
                ? r.advertisementData.advName
                : r.device.platformName.isNotEmpty
                    ? r.device.platformName
                    : 'Unknown BLE Peripheral';

            final id = r.device.remoteId.str;
            final existingIdx = _discoveredDevices.indexWhere((d) => d.id == id);
            final model = BleDeviceModel(
              id: id,
              name: name,
              rssi: r.rssi,
              isMock: false,
            );

            if (existingIdx >= 0) {
              _discoveredDevices[existingIdx] = model;
            } else {
              _discoveredDevices.add(model);
            }
          }
          _scanResultsController.add(List.unmodifiable(_discoveredDevices));
        });
      }
    } catch (e) {
      debugPrint('[SonicBLE] Hardware BLE scan unavailable ($e).');
    }
  }

  /// Stops BLE scanning.
  Future<void> stopScan() async {
    _isScanning = false;
    try {
      await FlutterBluePlus.stopScan();
      await _fbpSubscription?.cancel();
    } catch (_) {}
  }

  /// Handles a real-time state change for a discovered device.
  /// Injects advertisement data into the live discovery list.
  void handleAdvertisementData(
    String deviceId,
    String deviceName,
    int rssi,
  ) {
    final existingIdx = _discoveredDevices.indexWhere((d) => d.id == deviceId);
    final model = BleDeviceModel(
      id: deviceId,
      name: deviceName,
      rssi: rssi,
      isMock: false,
    );

    if (existingIdx >= 0) {
      _discoveredDevices[existingIdx] = model;
    } else {
      _discoveredDevices.add(model);
    }
    _scanResultsController.add(List.unmodifiable(_discoveredDevices));
  }

  /// Connects to a real BLE peripheral discovered during the live scan.
  Future<bool> connect(String deviceId) async {
    final targetIdx = _discoveredDevices.indexWhere((d) => d.id == deviceId);
    if (targetIdx < 0) return false;

    final target = _discoveredDevices[targetIdx];
    _connectedDevice = target.copyWith(connectionState: BleConnectionState.connecting);
    _connectedDeviceController.add(_connectedDevice);

    await stopScan();

    // Physical BLE connection
    try {
      final device = BluetoothDevice.fromId(deviceId);
      await device.connect(timeout: const Duration(seconds: 8));
      _connectedDevice = target.copyWith(connectionState: BleConnectionState.connected);
      _connectedDeviceController.add(_connectedDevice);
      return true;
    } catch (e) {
      debugPrint('[SonicBLE] Failed to connect to physical peripheral ($e)');
      _connectedDevice = null;
      _connectedDeviceController.add(null);
      return false;
    }
  }

  /// Disconnects from the active real BLE peripheral.
  Future<void> disconnect() async {
    if (_connectedDevice == null) return;

    try {
      final device = BluetoothDevice.fromId(_connectedDevice!.id);
      await device.disconnect();
    } catch (_) {}

    _connectedDevice = null;
    _connectedDeviceController.add(null);
  }

  /// Sends tactile alert pattern to connected wearable earpiece.
  Future<void> sendHapticAlert(List<int> pattern) async {
    if (_connectedDevice == null || !_connectedDevice!.isConnected) return;

    debugPrint('[SonicBLE] Transmitting haptic packet to ${_connectedDevice!.name}: $pattern');
    // Future hardware drop-in:
    // await hapticCharacteristic.write(patternBytes);
  }

  void dispose() {
    stopScan();
    disconnect();
    _scanResultsController.close();
    _connectedDeviceController.close();
  }
}
