/// Status of BLE connection to wearable sound-alert earpiece.
enum BleConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  disconnecting,
}

/// Represents a discovered or connected Bluetooth Low Energy device.
class BleDeviceModel {
  final String id;
  final String name;
  final int rssi;
  final BleConnectionState connectionState;
  final int? batteryLevel;
  final bool isMock;

  const BleDeviceModel({
    required this.id,
    required this.name,
    required this.rssi,
    this.connectionState = BleConnectionState.disconnected,
    this.batteryLevel,
    this.isMock = false,
  });

  bool get isConnected => connectionState == BleConnectionState.connected;

  BleDeviceModel copyWith({
    String? id,
    String? name,
    int? rssi,
    BleConnectionState? connectionState,
    int? batteryLevel,
    bool? isMock,
  }) {
    return BleDeviceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      rssi: rssi ?? this.rssi,
      connectionState: connectionState ?? this.connectionState,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      isMock: isMock ?? this.isMock,
    );
  }
}
