import 'package:flutter/material.dart';
import '../../../../core/theme/sonic_colors.dart';

/// Live oscilloscope waveform renderer for real-time audio visualization.
class WaveformWidget extends StatelessWidget {
  final List<double> samples;
  final double height;
  final Color strokeColor;
  final bool showFill;

  const WaveformWidget({
    super.key,
    required this.samples,
    this.height = 70.0,
    this.strokeColor = SonicColors.primary,
    this.showFill = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: SonicColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SonicColors.surfaceBorder, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
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
        ..color = strokeColor.withAlpha(80)
        ..strokeWidth = 1.5;
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        linePaint,
      );
      return;
    }

    final midY = size.height / 2;
    final path = Path();
    final fillPath = Path();

    // Downsample samples to match horizontal pixel resolution
    const step = 64; // step down 16000 samples into ~250 points
    final count = samples.length ~/ step;
    final dx = size.width / (count > 0 ? count : 1);

    path.moveTo(0, midY);
    fillPath.moveTo(0, size.height);
    fillPath.lineTo(0, midY);

    for (int i = 0; i < count; i++) {
      final idx = (i * step).clamp(0, samples.length - 1);
      final sample = samples[idx];
      // Scale amplitude to 80% of container height
      final y = midY - (sample * (size.height * 0.42));
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
            strokeColor.withAlpha(90),
            strokeColor.withAlpha(0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawPath(fillPath, fillPaint);
    }

    final linePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
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
