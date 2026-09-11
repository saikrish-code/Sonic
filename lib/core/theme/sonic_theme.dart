import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'sonic_colors.dart';

/// Minimalist, high-contrast theme styled after the 2025 Aura AI / Afterglow design.
class SonicTheme {
  static ThemeData get darkTheme {
    final baseTextTheme = ThemeData.dark().textTheme;
    final typography = GoogleFonts.plusJakartaSansTextTheme(baseTextTheme).copyWith(
      displayLarge: GoogleFonts.plusJakartaSans(
        color: SonicColors.textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 34,
        letterSpacing: -0.8,
        height: 1.15,
      ),
      displayMedium: GoogleFonts.plusJakartaSans(
        color: SonicColors.textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 28,
        letterSpacing: -0.6,
        height: 1.2,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        color: SonicColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 22,
        letterSpacing: -0.4,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        color: SonicColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 18,
        letterSpacing: -0.2,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        color: SonicColors.textSecondary,
        fontWeight: FontWeight.w500,
        fontSize: 15,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        color: SonicColors.textPrimary,
        fontWeight: FontWeight.w400,
        fontSize: 15,
        height: 1.4,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        color: SonicColors.textSecondary,
        fontWeight: FontWeight.w400,
        fontSize: 13,
      ),
      labelLarge: GoogleFonts.plusJakartaSans(
        color: SonicColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 13,
        letterSpacing: 0.1,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: SonicColors.background,
      primaryColor: SonicColors.primary,
      textTheme: typography,
      colorScheme: const ColorScheme.dark(
        primary: SonicColors.primary,
        secondary: SonicColors.secondary,
        surface: SonicColors.surface,
        error: SonicColors.alertRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: SonicColors.textPrimary,
        onError: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: SonicColors.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: SonicColors.surfaceBorder, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: SonicColors.textPrimary),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: SonicColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: SonicColors.textPrimary,
        unselectedItemColor: SonicColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SonicColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: SonicColors.textPrimary,
          side: const BorderSide(color: SonicColors.surfaceBorderLight, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: SonicColors.primary,
        inactiveTrackColor: SonicColors.surfaceLight,
        thumbColor: Colors.white,
        overlayColor: SonicColors.primary.withAlpha(40),
        trackHeight: 6,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: SonicColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: SonicColors.surfaceBorder),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: SonicColors.surfaceLight,
        contentTextStyle: GoogleFonts.plusJakartaSans(
          color: SonicColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: SonicColors.surfaceBorder),
        ),
      ),
    );
  }
}
