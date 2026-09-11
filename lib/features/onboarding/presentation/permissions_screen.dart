import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/sonic_colors.dart';
import '../../navigation/app_scaffold.dart';

class PermissionsScreen extends ConsumerStatefulWidget {
  const PermissionsScreen({super.key});

  @override
  ConsumerState<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends ConsumerState<PermissionsScreen> {
  bool _micGranted = false;
  bool _notifGranted = false;
  bool _hasDeniedOnce = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final mic = await Permission.microphone.status;
    final notif = await Permission.notification.status;
    if (mounted) {
      setState(() {
        _micGranted = mic.isGranted;
        _notifGranted = notif.isGranted;
      });
    }
  }

  Future<void> _requestMic() async {
    final status = await Permission.microphone.request();
    if (mounted) {
      setState(() {
        _micGranted = status.isGranted;
        if (status.isPermanentlyDenied || status.isDenied) {
          _hasDeniedOnce = true;
        }
      });
    }
  }

  Future<void> _requestNotif() async {
    final notifService = ref.read(notificationServiceProvider);
    final granted = await notifService.requestPermission();
    if (mounted) {
      setState(() {
        _notifGranted = granted;
        if (!granted) {
          _hasDeniedOnce = true;
        }
      });
    }
  }

  void _continue() {
    // Start audio listening
    ref.read(audioRecorderServiceProvider).startListening();
    ref.read(detectionCoordinatorProvider); // Initialize coordinator

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AppScaffold()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allGranted = _micGranted && _notifGranted;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const Text(
                'Permissions Required',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'To simulate a wearable earpiece on your phone, Sonic needs two critical permissions with complete on-device privacy.',
                style: TextStyle(
                  fontSize: 14,
                  color: SonicColors.textSecondary,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 28),

              // 1. Microphone Card
              _PermissionCard(
                icon: Icons.mic,
                iconColor: SonicColors.primary,
                title: 'Microphone Access',
                description:
                    'Listens for rolling 1-second audio windows to convert into log-mel spectrograms. Raw audio stays strictly on your device and is never uploaded.',
                isGranted: _micGranted,
                onRequest: _requestMic,
              ),

              const SizedBox(height: 16),

              // 2. Notification Card
              _PermissionCard(
                icon: Icons.notifications_active,
                iconColor: SonicColors.alertAmber,
                title: 'Notification Access',
                description:
                    'Fires instant heads-up banners with sound classification, urgency, and confidence scores when a critical sound is detected.',
                isGranted: _notifGranted,
                onRequest: _requestNotif,
              ),

              const Spacer(),

              // Graceful denial guidance
              if (_hasDeniedOnce && !allGranted) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: SonicColors.alertOrange.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: SonicColors.alertOrange.withAlpha(120)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, color: SonicColors.alertOrange),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'If a permission was blocked, please enable it in your device settings to allow Sonic to listen.',
                          style: TextStyle(fontSize: 12, color: SonicColors.textPrimary),
                        ),
                      ),
                      TextButton(
                        onPressed: openAppSettings,
                        child: const Text('Settings'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _continue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        allGranted ? SonicColors.primary : SonicColors.surfaceLight,
                    foregroundColor:
                        allGranted ? Colors.black : SonicColors.textPrimary,
                  ),
                  child: Text(
                    allGranted ? 'Enter Sonic' : 'Continue Anyway (Demo Mode)',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final bool isGranted;
  final VoidCallback onRequest;

  const _PermissionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.isGranted,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: SonicColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isGranted
              ? SonicColors.alertGreen.withAlpha(120)
              : SonicColors.surfaceBorder,
          width: isGranted ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(35),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isGranted ? 'Permission Granted' : 'Action Required',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isGranted ? SonicColors.alertGreen : SonicColors.alertOrange,
                      ),
                    ),
                  ],
                ),
              ),
              if (isGranted)
                const Icon(Icons.check_circle, color: SonicColors.alertGreen, size: 24)
              else
                ElevatedButton(
                  onPressed: onRequest,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    backgroundColor: iconColor,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Allow', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: SonicColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
