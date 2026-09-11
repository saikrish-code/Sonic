import 'package:flutter/material.dart';

/// Design tokens and color palette for Sonic
class SonicColors {
  // Backgrounds & Surfaces (OLED / Obsidian Dark Theme)
  static const Color background = Color(0xFF0A0E17);
  static const Color surface = Color(0xFF131B2A);
  static const Color surfaceLight = Color(0xFF1E293B);
  static const Color surfaceBorder = Color(0xFF2E3D56);
  static const Color cardBg = Color(0xFF162032);

  // Accents & Brand
  static const Color primary = Color(0xFF00F0FF);      // Electric Cyan / Sonic Pulse
  static const Color primaryDark = Color(0xFF00B4D8);
  static const Color secondary = Color(0xFF7928CA);    // Neon Violet
  static const Color accentPurple = Color(0xFF9D4EDD);

  // Status & Alerts
  static const Color alertRed = Color(0xFFFF2A6D);     // Critical Danger / Smoke / Fire
  static const Color alertOrange = Color(0xFFFF8C00);  // High Alert / Siren
  static const Color alertAmber = Color(0xFFFFB703);   // Warning / Doorbell / Knock
  static const Color alertGreen = Color(0xFF05FFA1);   // Safe / Active / Connected
  static const Color alertBlue = Color(0xFF3A86FF);    // Info / Personal Sound

  // Text & Content (Accessibility High Contrast)
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textDisabled = Color(0xFF475569);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00F0FF), Color(0xFF7928CA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient alertGradient = LinearGradient(
    colors: [Color(0xFFFF2A6D), Color(0xFFFF8C00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient listeningActiveGradient = LinearGradient(
    colors: [Color(0xFF05FFA1), Color(0xFF00F0FF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
