import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralised colour palette — E-Care brand system.
///
/// Anchors:
///  • Teal `#07A996` — primary brand
///  • Mint `#E7F2F1` — surface / app background
///  • Ink  `#040707` — text headings
///  • Slate `#5B5B5B` — secondary text
class AppColors {
  AppColors._();

  // Primary (teal)
  static const Color primary = Color(0xFF07A996);
  static const Color primaryLight = Color(0xFF4FC3B5);
  static const Color primaryDark = Color(0xFF05756A);

  // Mint surfaces (the soft greenish backgrounds in the design)
  static const Color mint = Color(0xFFE7F2F1);
  static const Color mintDeep = Color(0xFFB7DDD8);

  // Secondary accent (kept for legacy refs — same teal family)
  static const Color secondary = Color(0xFF07A996);
  static const Color secondaryLight = Color(0xFF4FC3B5);
  static const Color secondaryDark = Color(0xFF05756A);

  // Neutral
  static const Color background = mint;
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF22B07D);
  static const Color warning = Color(0xFFF5A524);
  static const Color info = Color(0xFF07A996);

  // Text
  static const Color textPrimary = Color(0xFF040707);
  static const Color textSecondary = Color(0xFF5B5B5B);
  static const Color textHint = Color(0xFFB0B7B6);

  // Dark-theme overrides
  static const Color darkBackground = Color(0xFF0B1413);
  static const Color darkSurface = Color(0xFF132220);
  static const Color darkCard = Color(0xFF1B2E2B);
}

/// Provides light and dark [ThemeData].
class ThemeConfig {
  ThemeConfig._();

  static TextTheme _albert(TextTheme base, Color body) {
    return GoogleFonts.albertSansTextTheme(
      base,
    ).apply(bodyColor: body, displayColor: body);
  }

  // ──────────── Light ────────────
  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        secondary: AppColors.primary,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.mint,
    );

    return base.copyWith(
      textTheme: _albert(base.textTheme, AppColors.textPrimary),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.mint,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.albertSans(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          elevation: 0,
          textStyle: GoogleFonts.albertSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.4),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: GoogleFonts.albertSans(color: AppColors.textHint),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFEAEEED),
        thickness: 1,
        space: 1,
      ),
    );
  }

  // ──────────── Dark ────────────
  static ThemeData get darkTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        primary: AppColors.primaryLight,
        secondary: AppColors.primaryLight,
        surface: AppColors.darkSurface,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
    );

    return base.copyWith(
      textTheme: _albert(base.textTheme, Colors.white),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.albertSans(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          elevation: 0,
          textStyle: GoogleFonts.albertSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkCard,
        hintStyle: GoogleFonts.albertSans(color: AppColors.textHint),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(
            color: AppColors.primaryLight,
            width: 1.4,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
    );
  }
}
