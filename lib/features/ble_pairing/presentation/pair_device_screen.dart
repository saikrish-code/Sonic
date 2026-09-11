import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/ble/ble_device_model.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/sonic_colors.dart';

class PairDeviceScreen extends ConsumerStatefulWidget {
  const PairDeviceScreen({super.key});

  @override
  ConsumerState<PairDeviceScreen> createState() => _PairDeviceScreenState();
}

class _PairDeviceScreenState extends ConsumerState<PairDeviceScreen> {
  @override
  void initState() {
    super.initState();
    // Automatically trigger initial scan on screen open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bleServiceProvider).startScan();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bleService = ref.read(bleServiceProvider);
    final scanResultsAsync = ref.watch(bleScanResultsProvider);
    final connectedDeviceAsync = ref.watch(bleConnectedDeviceProvider);

    final devices = scanResultsAsync.asData?.value ?? [];
    final connectedDevice = connectedDeviceAsync.asData?.value;
    final isScanning = bleService.isScanning;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pair Wearable Earpiece'),
        actions: [
          IconButton(
            icon: Icon(
              isScanning ? Icons.stop : Icons.refresh,
              color: SonicColors.primary,
            ),
            tooltip: isScanning ? 'Stop Scan' : 'Scan for Devices',
            onPressed: () {
              if (isScanning) {
                bleService.stopScan();
              } else {
                bleService.startScan();
              }
              setState(() {});
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active connected wearable hero card
            if (connectedDevice != null && connectedDevice.isConnected) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: SonicColors.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: SonicColors.alertGreen, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: SonicColors.alertGreen.withAlpha(50),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: SonicColors.alertGreen.withAlpha(40),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.hearing,
                            color: SonicColors.alertGreen,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: SonicColors.alertGreen.withAlpha(40),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'CONNECTED',
                                      style: TextStyle(
                                        color: SonicColors.alertGreen,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (connectedDevice.batteryLevel != null)
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.battery_charging_full,
                                          size: 14,
                                          color: SonicColors.alertGreen,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${connectedDevice.batteryLevel}%',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: SonicColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                connectedDevice.name,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                connectedDevice.id,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: SonicColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: SonicColors.surfaceBorder),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              bleService.sendHapticAlert([0, 150, 100, 150]);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Test haptic pulse sent to earpiece!'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            icon: const Icon(Icons.vibration, size: 18),
                            label: const Text('Test Vibration'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: SonicColors.alertRed,
                            side: const BorderSide(color: SonicColors.alertRed),
                          ),
                          onPressed: () async {
                            await bleService.disconnect();
                          },
                          child: const Text('Disconnect'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Section: Scanner radar & status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: SonicColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: SonicColors.surfaceBorder),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: isScanning
                        ? const CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: SonicColors.primary,
                          )
                        : const Icon(Icons.bluetooth_searching, color: SonicColors.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isScanning
                              ? 'Scanning for Sonic Wearables...'
                              : 'Scan Stopped',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Discovered ${devices.length} nearby Bluetooth peripherals',
                          style: const TextStyle(
                            fontSize: 12,
                            color: SonicColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (isScanning) {
                        bleService.stopScan();
                      } else {
                        bleService.startScan();
                      }
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    child: Text(isScanning ? 'Stop' : 'Scan'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Discovered Devices',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: SonicColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            if (devices.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                child: const Column(
                  children: [
                    Icon(Icons.bluetooth_disabled, size: 48, color: SonicColors.textMuted),
                    SizedBox(height: 12),
                    Text(
                      'No BLE devices detected yet.',
                      style: TextStyle(color: SonicColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  final device = devices[index];
                  final isTargetConnected =
                      connectedDevice?.id == device.id && connectedDevice?.isConnected == true;
                  final isTargetConnecting = connectedDevice?.id == device.id &&
                      connectedDevice?.connectionState == BleConnectionState.connecting;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isTargetConnected
                          ? SonicColors.alertGreen.withAlpha(20)
                          : SonicColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isTargetConnected
                            ? SonicColors.alertGreen
                            : SonicColors.surfaceBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: device.isMock
                                ? SonicColors.primary.withAlpha(30)
                                : SonicColors.surfaceLight,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            device.isMock ? Icons.hearing : Icons.bluetooth,
                            color: device.isMock
                                ? SonicColors.primary
                                : SonicColors.textSecondary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      device.name,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (device.isMock) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: SonicColors.primary.withAlpha(35),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'PROTOTYPE',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: SonicColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${device.id} • Signal: ${device.rssi} dBm',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: SonicColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isTargetConnecting) ...[
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ] else if (isTargetConnected) ...[
                          const Icon(Icons.check_circle, color: SonicColors.alertGreen),
                        ] else ...[
                          ElevatedButton(
                            onPressed: () async {
                              final success = await bleService.connect(device.id);
                              if (success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Connected to ${device.name}!'),
                                    backgroundColor: SonicColors.alertGreen.withAlpha(80),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                            child: const Text('Pair'),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: 24),

            // Hardware Drop-in Notice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: SonicColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: SonicColors.surfaceBorder),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hardware Integration Specification',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: SonicColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'This BLE module is fully decoupled. Once custom wearable earpieces or tactile clips are fabricated, drop the production GATT Characteristic UUID into BleService to route tactile pulses to physical hardware without altering the audio or ML pipeline.',
                    style: TextStyle(
                      fontSize: 11,
                      color: SonicColors.textMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
