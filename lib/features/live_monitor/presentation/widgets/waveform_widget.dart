import 'package:flutter/material.dart';

/// Live oscilloscope waveform renderer matching the glowing neon curve in Aura AI design.
class WaveformWidget extends StatelessWidget {
  final List<double> samples;
  final double height;
  final Color strokeColor;
  final bool showFill;

  const WaveformWidget({
    super.key,
    required this.samples,
    this.height = 70.0,
    this.strokeColor = const Color(0xFF8D7AFF),
    this.showFill = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _WaveformPainter(
          samples: samples,
          strokeColor: strokeColor,
          showFill: showFill,
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> samples;
  final Color strokeColor;
  final bool showFill;

  _WaveformPainter({
    required this.samples,
    required this.strokeColor,
    required this.showFill,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty) {
      final linePaint = Paint()
        ..color = strokeColor.withAlpha(50)
        ..strokeWidth = 2.0;
      final p = Path()
        ..moveTo(0, size.height * 0.6)
        ..quadraticBezierTo(
          size.width * 0.25,
          size.height * 0.2,
          size.width * 0.5,
          size.height * 0.6,
        )
        ..quadraticBezierTo(
          size.width * 0.75,
          size.height * 0.9,
          size.width,
          size.height * 0.5,
        );
      canvas.drawPath(p, linePaint);
      return;
    }

    final midY = size.height * 0.55;
    final path = Path();
    final fillPath = Path();

    const step = 64;
    final count = samples.length ~/ step;
    final dx = size.width / (count > 1 ? count - 1 : 1);

    path.moveTo(0, midY);
    fillPath.moveTo(0, size.height);
    fillPath.lineTo(0, midY);

    for (int i = 0; i < count; i++) {
      final idx = (i * step).clamp(0, samples.length - 1);
      final sample = samples[idx];
      final y = (midY - (sample * (size.height * 0.45))).clamp(4.0, size.height - 4.0);
      final x = i * dx;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      fillPath.lineTo(x, y);
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    if (showFill) {
      final fillPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            strokeColor.withAlpha(70),
            strokeColor.withAlpha(0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawPath(fillPath, fillPaint);
    }

    // Glow shadow line
    final glowPaint = Paint()
      ..color = strokeColor.withAlpha(100)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(path, glowPaint);

    // Main sharp line
    final linePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.samples != samples ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.showFill != showFill;
  }
}
