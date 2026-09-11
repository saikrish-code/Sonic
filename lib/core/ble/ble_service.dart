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

  // Mock Sonic Earpieces for pairing simulation
  static final List<BleDeviceModel> _mockDevices = [
    const BleDeviceModel(
      id: 'SO:NI:C0:01:EA:22',
      name: 'Sonic Smart Earpiece (Left)',
      rssi: -52,
      batteryLevel: 94,
      isMock: true,
    ),
    const BleDeviceModel(
      id: 'SO:NI:C0:02:EA:33',
      name: 'Sonic Haptic Clip Pro',
      rssi: -68,
      batteryLevel: 81,
      isMock: true,
    ),
  ];

  /// Starts scanning for nearby BLE peripherals.
  Future<void> startScan() async {
    if (_isScanning) return;
    _isScanning = true;
    _discoveredDevices.clear();

    // Include mock Sonic wearable prototypes for testing
    _discoveredDevices.addAll(_mockDevices);
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
      debugPrint('[SonicBLE] Hardware BLE scan unavailable ($e). Mock devices active.');
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

  /// Connects to a device (handles both mock simulation and physical peripheral).
  Future<bool> connect(String deviceId) async {
    final targetIdx = _discoveredDevices.indexWhere((d) => d.id == deviceId);
    if (targetIdx < 0) return false;

    final target = _discoveredDevices[targetIdx];
    _connectedDevice = target.copyWith(connectionState: BleConnectionState.connecting);
    _connectedDeviceController.add(_connectedDevice);

    await stopScan();

    if (target.isMock) {
      // Mock connection sequence
      await Future.delayed(const Duration(milliseconds: 900));
      _connectedDevice = target.copyWith(
        connectionState: BleConnectionState.connected,
        batteryLevel: target.batteryLevel ?? 88,
      );
      _connectedDeviceController.add(_connectedDevice);
      return true;
    } else {
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
  }

  /// Disconnects from active device.
  Future<void> disconnect() async {
    if (_connectedDevice == null) return;

    if (!_connectedDevice!.isMock) {
      try {
        final device = BluetoothDevice.fromId(_connectedDevice!.id);
        await device.disconnect();
      } catch (_) {}
    }

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
