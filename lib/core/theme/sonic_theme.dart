import 'package:flutter/material.dart';
import 'sonic_colors.dart';

class SonicTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: SonicColors.background,
      primaryColor: SonicColors.primary,
      colorScheme: const ColorScheme.dark(
        primary: SonicColors.primary,
        secondary: SonicColors.secondary,
        surface: SonicColors.surface,
        error: SonicColors.alertRed,
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: SonicColors.textPrimary,
        onError: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: SonicColors.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: SonicColors.surfaceBorder, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: SonicColors.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: SonicColors.textPrimary),
        titleTextStyle: TextStyle(
          color: SonicColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: SonicColors.surface,
        selectedItemColor: SonicColors.primary,
        unselectedItemColor: SonicColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SonicColors.primary,
          foregroundColor: Colors.black,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: SonicColors.primary,
          side: const BorderSide(color: SonicColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: SonicColors.primary,
        inactiveTrackColor: SonicColors.surfaceLight,
        thumbColor: SonicColors.primary,
        overlayColor: SonicColors.primary.withAlpha(50),
        trackHeight: 4,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: SonicColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: SonicColors.surfaceBorder),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: SonicColors.surfaceLight,
        contentTextStyle: const TextStyle(color: SonicColors.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: SonicColors.surfaceBorder),
        ),
      ),
    );
  }
}
