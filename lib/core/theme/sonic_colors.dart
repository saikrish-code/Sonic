import 'package:flutter/material.dart';

/// Design tokens and color palette for Sonic
/// Styled to match the 2025 "Afterglow / Aura AI" concept:
/// Deep midnight obsidian, glowing violet/purple gradients, and electric periwinkle accents.
class SonicColors {
  // Backgrounds & Surfaces (Obsidian Midnight with Violet Undertone)
  static const Color background = Color(0xFF090814);
  static const Color backgroundSecondary = Color(0xFF0E0B1E);
  static const Color surface = Color(0xFF141026);
  static const Color surfaceLight = Color(0xFF1C1736);
  static const Color surfaceBorder = Color(0xFF28214B);
  static const Color surfaceBorderLight = Color(0xFF382F63);
  static const Color cardBg = Color(0xFF141126);
  static const Color cardBgElevated = Color(0xFF191530);

  // Accents & Brand (Aura Electric Violet / Lavender Glow)
  static const Color primary = Color(0xFF5E45FF);       // Electric Violet / Aura Brand
  static const Color primaryLight = Color(0xFF8D7AFF);  // Soft Lavender
  static const Color primaryDark = Color(0xFF4530D6);
  static const Color secondary = Color(0xFF9E54FF);     // Luminous Violet
  static const Color accentPurple = Color(0xFFC084FC);  // Periwinkle Highlight
  static const Color auraGlow = Color(0x356A45FF);

  // Status & Alerts (Refined for Dark Violet Aura Aesthetics)
  static const Color alertRed = Color(0xFFFF3B69);      // Urgent Danger / Smoke Alarm
  static const Color alertOrange = Color(0xFFFF8B3D);   // High Alert / Siren
  static const Color alertAmber = Color(0xFFFFB84D);    // Attention / Doorbell / Knock
  static const Color alertGreen = Color(0xFF00E599);    // Safe / Listening Active
  static const Color alertBlue = Color(0xFF4D9FFF);     // Info / General

  // Typography & Content (Minimal, Clean, High Contrast)
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA5A1B8);
  static const Color textMuted = Color(0xFF6B6682);
  static const Color textDisabled = Color(0xFF45405A);

  // Signature Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C53FF), Color(0xFF4B33E0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroCardGradient = LinearGradient(
    colors: [Color(0xFF5F46FF), Color(0xFF5038E8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGlowGradient = LinearGradient(
    colors: [Color(0xFF1A1535), Color(0xFF110E24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient waveGlowGradient = LinearGradient(
    colors: [Color(0xCC7F53FF), Color(0x00141026)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient listeningActiveGradient = LinearGradient(
    colors: [Color(0xFF8D7AFF), Color(0xFF5E45FF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
