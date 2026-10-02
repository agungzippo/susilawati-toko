import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Palet Resmi SUSILAWATI TOKO dari design-system/susilawati-toko/MASTER.md
  static const Color primary = Color(0xFF334155); // Slate 700
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color secondary = Color(0xFF475569); // Slate 600
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color accent = Color(0xFF059669); // Emerald 600 (Sukses / CTA)
  static const Color onAccent = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color foreground = Color(0xFF0F172A); // Slate 900
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardForeground = Color(0xFF0F172A);
  static const Color muted = Color(0xFFF1F5F9); // Slate 100
  static const Color mutedForeground = Color(0xFF64748B); // Slate 500
  static const Color border = Color(0xFFE2E8F0); // Slate 200
  static const Color warning = Color(0xFFD97706); // Amber 600 (Stok Menipis)
  static const Color destructive = Color(0xFFDC2626); // Red 600 (Stok Habis / Rusak)
  static const Color onDestructive = Color(0xFFFFFFFF);
}

class AppTheme {
  static ThemeData get lightTheme {
    final baseTextTheme = ThemeData.light().textTheme;

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        error: AppColors.destructive,
        onError: AppColors.onDestructive,
        surface: AppColors.card,
        onSurface: AppColors.foreground,
      ),
      textTheme: GoogleFonts.nunitoSansTextTheme(baseTextTheme).copyWith(
        displayLarge: GoogleFonts.rubik(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.foreground,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        displayMedium: GoogleFonts.rubik(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.foreground,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        titleLarge: GoogleFonts.rubik(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.foreground,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        titleMedium: GoogleFonts.rubik(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.foreground,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        bodyLarge: GoogleFonts.nunitoSans(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: AppColors.foreground,
        ),
        bodyMedium: GoogleFonts.nunitoSans(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppColors.foreground,
        ),
        labelLarge: GoogleFonts.nunitoSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.foreground,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.rubik(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.onPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.onAccent,
          minimumSize: const Size.fromHeight(48), // Minimal 48 dp touch target
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.rubik(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: AppColors.border, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.rubik(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.destructive),
        ),
      ),
    );
  }
}
