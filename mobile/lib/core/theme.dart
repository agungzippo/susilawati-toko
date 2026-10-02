import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Palet Warna Mewah Butik Tas SUSILAWATI TOKO (Sesuai Mockup UI)
  static const Color brandEspresso = Color(0xFF3D2F28); // Kopi pekat / Kulit tua
  static const Color brandCoffee = Color(0xFF4A3B32); // Cokelat kopi
  static const Color brandWarm = Color(0xFF6E5849); // Warm leather
  static const Color brandLightBeige = Color(0xFFF7F4F0); // Latar belakang utama
  static const Color cardWhite = Color(0xFFFFFFFF); // Kartu putih bersih
  static const Color tileBeige = Color(0xFFF3EFEA); // Kotak aksi 3D
  static const Color borderWarm = Color(0xFFECE6DE); // Garis batas halus

  // Warna Teks
  static const Color textDark = Color(0xFF1F1915); // Hitam pekat elegan
  static const Color textMuted = Color(0xFF8C7E76); // Abu-abu taupe

  // Aksen Status
  static const Color greenStock = Color(0xFF2E7D32); // Hijau stok aman
  static const Color redStock = Color(0xFFDC2626); // Merah stok keluar / habis
  static const Color amberStock = Color(0xFFD97706); // Kuning peringatan

  // Aliases for compatibility
  static const Color primary = brandEspresso;
  static const Color background = brandLightBeige;
  static const Color border = borderWarm;
  static const Color mutedForeground = textMuted;
  static const Color foreground = textDark;
  static const Color card = cardWhite;
  static const Color destructive = redStock;
  static const Color warning = amberStock;
  static const Color accent = brandWarm;

  // Bayangan 3D Lembut & Kedalaman Fisik (UI/UX Pro Max)
  static List<BoxShadow> get shadow3D => [
        BoxShadow(
          color: const Color(0xFF261D17).withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: const Color(0xFF261D17).withValues(alpha: 0.03),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get shadow3DElevated => [
        BoxShadow(
          color: const Color(0xFF261D17).withValues(alpha: 0.12),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: const Color(0xFF261D17).withValues(alpha: 0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get buttonShadow3D => [
        BoxShadow(
          color: const Color(0xFF1E1612),
          offset: const Offset(0, 4),
          blurRadius: 0,
        ),
        BoxShadow(
          color: const Color(0xFF3D2F28).withValues(alpha: 0.25),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get buttonShadow3DPressed => [
        BoxShadow(
          color: const Color(0xFF1E1612),
          offset: const Offset(0, 1),
          blurRadius: 0,
        ),
        BoxShadow(
          color: const Color(0xFF3D2F28).withValues(alpha: 0.15),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  // Gradien Lembut Permukaan 3D (Cushion / Leather Sheen)
  static const LinearGradient cardGradient3D = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFFAF7F3),
    ],
  );

  static const LinearGradient espressoGradient3D = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF4A3B32),
      Color(0xFF32251F),
    ],
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    final baseTextTheme = ThemeData.light().textTheme;

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.brandLightBeige,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.brandEspresso,
        onPrimary: Colors.white,
        secondary: AppColors.brandWarm,
        onSecondary: Colors.white,
        error: AppColors.redStock,
        onError: Colors.white,
        surface: AppColors.cardWhite,
        onSurface: AppColors.textDark,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(baseTextTheme).copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 30,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
          letterSpacing: -0.3,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppColors.textDark,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.normal,
          color: AppColors.textMuted,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderWarm, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandEspresso,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          elevation: 2,
          shadowColor: AppColors.brandEspresso.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brandEspresso,
          minimumSize: const Size.fromHeight(50),
          side: const BorderSide(color: AppColors.borderWarm, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderWarm),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderWarm),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.brandEspresso, width: 1.5),
        ),
      ),
    );
  }
}
