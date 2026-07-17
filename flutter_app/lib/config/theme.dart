import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Unified design system tokens and ThemeData builder.
class AppTheme {
  AppTheme._();

  // ─── LIGHT MODE COLOR SYSTEM ─────────────────────────
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color primaryLight = Color(0xFF4F7CFF);
  static const Color secondaryLight = Color(0xFF7C5CFF);
  static const Color accentLight = Color(0xFF00C896);
  static const Color textLight = Color(0xFF1E293B);
  static const Color textSecLight = Color(0xFF64748B);
  static const Color borderLight = Color(0xFFE5E7EB);

  // ─── DARK MODE COLOR SYSTEM ──────────────────────────
  static const Color bgDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF162033);
  static const Color cardDark = Color(0xFF1E293B);
  static const Color primaryDark = Color(0xFF5B8CFF);
  static const Color secondaryDark = Color(0xFF8B7DFF);
  static const Color accentDark = Color(0xFF00D9A5);
  static const Color textDark = Color(0xFFF8FAFC);
  static const Color textSecDark = Color(0xFFCBD5E1);
  static const Color borderDark = Color(0xFF334155);

  // Legacy Theme support for back-compat compatibility
  static const Color backgroundLight = bgLight;
  static const Color surfaceLight = cardLight;
  static const Color textPrimary = textLight;
  static const Color textSecondary = textSecLight;
  static const Color textMuted = textSecLight;
  static const Color accentPrimary = primaryLight;
  static const Color accentSecondary = secondaryLight;
  static const Color accentWarm = Colors.redAccent;
  static const Color accentGold = Colors.orangeAccent;
  static const Color cardElevated = cardLight;
  static const LinearGradient primaryGradient = LinearGradient(colors: [primaryLight, secondaryLight]);
  static const LinearGradient darkGradient = LinearGradient(colors: [bgDark, surfaceDark]);
  static const LinearGradient warmGradient = LinearGradient(colors: [accentWarm, accentWarm]);

  // ─── LIGHT THEME BUILDER ──────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgLight,
      primaryColor: primaryLight,
      colorScheme: const ColorScheme.light(
        primary: primaryLight,
        secondary: secondaryLight,
        tertiary: accentLight,
        surface: cardLight,
        error: Colors.redAccent,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textLight,
      ),
      textTheme: _textTheme(textLight, textSecLight),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.fredoka(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textLight,
        ),
        iconTheme: const IconThemeData(color: textLight),
      ),
      cardTheme: CardThemeData(
        color: cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderLight, width: 1.5),
        ),
      ),
      elevatedButtonTheme: _elevatedButtonTheme(primaryLight),
      outlinedButtonTheme: _outlinedButtonTheme(textLight, borderLight),
      inputDecorationTheme: _inputDecorationTheme(cardLight, borderLight, primaryLight, textSecLight),
    );
  }

  // ─── DARK THEME BUILDER ───────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      primaryColor: primaryDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryDark,
        secondary: secondaryDark,
        tertiary: accentDark,
        surface: cardDark,
        error: Colors.redAccent,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textDark,
      ),
      textTheme: _textTheme(textDark, textSecDark),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.fredoka(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textDark,
        ),
        iconTheme: const IconThemeData(color: textDark),
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderDark, width: 1.5),
        ),
      ),
      elevatedButtonTheme: _elevatedButtonTheme(primaryDark),
      outlinedButtonTheme: _outlinedButtonTheme(textDark, borderDark),
      inputDecorationTheme: _inputDecorationTheme(cardDark, borderDark, primaryDark, textSecDark),
    );
  }

  // ─── SHARED BASE BUILDERS ─────────────────────────────
  
  static TextTheme _textTheme(Color mainColor, Color secColor) {
    return TextTheme(
      displayLarge: GoogleFonts.fredoka(fontSize: 40, fontWeight: FontWeight.w800, color: mainColor, letterSpacing: -0.5),
      displayMedium: GoogleFonts.fredoka(fontSize: 32, fontWeight: FontWeight.w700, color: mainColor, letterSpacing: -0.5),
      displaySmall: GoogleFonts.fredoka(fontSize: 24, fontWeight: FontWeight.w700, color: mainColor),
      headlineLarge: GoogleFonts.fredoka(fontSize: 22, fontWeight: FontWeight.w600, color: mainColor),
      headlineMedium: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.w600, color: mainColor),
      headlineSmall: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.w600, color: mainColor),
      titleLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: mainColor),
      titleMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: secColor),
      titleSmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: secColor),
      bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: mainColor),
      bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: secColor),
      bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: secColor.withOpacity(0.8)),
      labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme(Color bgColor) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );
  }

  static OutlinedButtonThemeData _outlinedButtonTheme(Color textColor, Color borderColor) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: textColor,
        side: BorderSide(color: borderColor, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );
  }

  static InputDecorationTheme _inputDecorationTheme(Color fillColor, Color borderColor, Color activeColor, Color hintColor) {
    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: activeColor, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      hintStyle: GoogleFonts.inter(color: hintColor.withOpacity(0.6), fontSize: 15),
      labelStyle: GoogleFonts.inter(color: hintColor, fontSize: 15),
    );
  }
}
