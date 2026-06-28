import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'grabbit_colors.dart';

/// ThemeData for GRABBIT — FLUBBER/KYUUBI dark-matte workbench style.
abstract final class GrabbitTheme {
  static ThemeData get dark {
    final barlow = GoogleFonts.barlow();
    final mono = GoogleFonts.jetBrainsMono();

    return ThemeData.dark(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: GrabbitColors.void_,
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        primary: GrabbitColors.turquoise,
        onPrimary: GrabbitColors.white,
        secondary: GrabbitColors.orange,
        onSecondary: GrabbitColors.white,
        error: GrabbitColors.red,
        onError: GrabbitColors.white,
        surface: GrabbitColors.surface,
        onSurface: GrabbitColors.t1,
        outline: GrabbitColors.border,
      ),
      cardTheme: CardThemeData(
        color: GrabbitColors.card,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: GrabbitColors.border),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: GrabbitColors.void_,
        foregroundColor: GrabbitColors.t1,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: barlow.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: GrabbitColors.t1,
        ),
      ),
      textTheme: TextTheme(
        // Display — Lilita One (loaded separately via google_fonts)
        displayLarge: GoogleFonts.lilitaOne(
          fontSize: 48,
          color: GrabbitColors.t1,
        ),
        displayMedium: GoogleFonts.lilitaOne(
          fontSize: 36,
          color: GrabbitColors.t1,
        ),
        displaySmall: GoogleFonts.lilitaOne(
          fontSize: 28,
          color: GrabbitColors.t1,
        ),
        // Headings — Barlow bold
        headlineLarge: barlow.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: GrabbitColors.t1,
        ),
        headlineMedium: barlow.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: GrabbitColors.t1,
        ),
        headlineSmall: barlow.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: GrabbitColors.t1,
        ),
        // Body — Barlow regular
        bodyLarge: barlow.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: GrabbitColors.t2,
        ),
        bodyMedium: barlow.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: GrabbitColors.t2,
        ),
        bodySmall: barlow.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: GrabbitColors.t3,
        ),
        // Labels — Barlow semibold uppercase
        labelLarge: barlow.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: GrabbitColors.t1,
        ),
        labelMedium: barlow.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: GrabbitColors.t3,
        ),
        labelSmall: mono.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w400,
          color: GrabbitColors.t3,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: GrabbitColors.surface,
        selectedItemColor: GrabbitColors.turquoise,
        unselectedItemColor: GrabbitColors.t3,
        type: BottomNavigationBarType.fixed,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: GrabbitColors.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: GrabbitColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: GrabbitColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: GrabbitColors.turquoise, width: 2),
        ),
        hintStyle: const TextStyle(color: GrabbitColors.t4),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: GrabbitColors.surface,
        contentTextStyle: const TextStyle(color: GrabbitColors.t1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: GrabbitColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: GrabbitColors.turquoise,
        foregroundColor: GrabbitColors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),
    );
  }
}
