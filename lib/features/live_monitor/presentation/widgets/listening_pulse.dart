import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/sonic_colors.dart';

/// Animated concentric pulsing radar indicating active microphone listening and sound volume.
class ListeningPulseWidget extends StatefulWidget {
  final bool isListening;
  final double volume; // 0.0 to 1.0
  final double decibels;
  final VoidCallback onToggleListening;

  const ListeningPulseWidget({
    super.key,
    required this.isListening,
    required this.volume,
    required this.decibels,
    required this.onToggleListening,
  });

  @override
  State<ListeningPulseWidget> createState() => _ListeningPulseWidgetState();
}

class _ListeningPulseWidgetState extends State<ListeningPulseWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.isListening
        ? (widget.volume > 0.4 ? SonicColors.alertAmber : SonicColors.primary)
        : SonicColors.textMuted;

    return GestureDetector(
      onTap: widget.onToggleListening,
      child: SizedBox(
        width: 260,
        height: 260,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return CustomPaint(
              painter: _PulseWavePainter(
                progress: _pulseController.value,
                volume: widget.isListening ? widget.volume : 0.0,
                color: activeColor,
                isListening: widget.isListening,
              ),
              child: Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: widget.isListening
                        ? const LinearGradient(
                            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : const LinearGradient(
                            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                          ),
                    border: Border.all(
                      color: activeColor.withAlpha(200),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: activeColor.withAlpha(widget.isListening ? 90 : 20),
                        blurRadius: 28,
                        spreadRadius: widget.isListening ? (widget.volume * 14) : 0,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.isListening ? Icons.mic : Icons.mic_off,
                        color: activeColor,
                        size: 38,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.isListening
                            ? '${widget.decibels.toInt()} dB'
                            : 'PAUSED',
                        style: TextStyle(
                          color: activeColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PulseWavePainter extends CustomPainter {
  final double progress;
  final double volume;
  final Color color;
  final bool isListening;

  _PulseWavePainter({
    required this.progress,
    required this.volume,
    required this.color,
    required this.isListening,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isListening) return;

    final center = Offset(size.width / 2, size.height / 2);
    const baseRadius = 60.0;
    const maxRadius = 125.0;

    // 3 concentric animated ripples
    for (int i = 0; i < 3; i++) {
      final waveProgress = (progress + (i / 3.0)) % 1.0;
      final radius = baseRadius + (maxRadius - baseRadius) * waveProgress + (volume * 15.0);
      final alpha = ((1.0 - waveProgress) * 160 * (0.6 + volume * 0.4)).toInt().clamp(0, 255);

      final paint = Paint()
        ..color = color.withAlpha(alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 * (1.0 - waveProgress) + 0.5;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PulseWavePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.volume != volume ||
        oldDelegate.color != color ||
        oldDelegate.isListening != isListening;
  }
}
