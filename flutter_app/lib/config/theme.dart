import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bouncy, Neobrutalist Flat-3D Game Design System tokens.
/// Features thick borders, solid offset shadows, Outfit typography, and a lively sketchpad feel.
class AppTheme {
  AppTheme._();

  // ─── SPACING SYSTEM (8px grid) ────────────────────────
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space24 = 24;
  static const double space32 = 32;
  static const double space48 = 48;
  static const double space64 = 64;

  // ─── RADII ────────────────────────────────────────────
  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 16;

  // ─── LIGHT MODE COLOR SYSTEM ──────────────────────────
  static const Color bgLight = Color(0xFFFAF9FC);       // Soft lavender-white
  static const Color cardLight = Color(0xFFFFFFFF);      // Pure white
  static const Color primaryLight = Color(0xFF7C3AED);   // Vibrant Violet 600
  static const Color secondaryLight = Color(0xFF4F46E5); // Indigo 600
  static const Color accentLight = Color(0xFF10B981);    // Emerald 500
  static const Color textLight = Color(0xFF1E1B4B);      // Deep Indigo-Black
  static const Color textSecLight = Color(0xFF5850EC);   // Indigo-Muted
  static const Color borderLight = Color(0xFF1E1B4B);    // Thick solid dark border

  // ─── DARK MODE COLOR SYSTEM ───────────────────────────
  static const Color bgDark = Color(0xFF0C0A12);         // Rich dark purple-black
  static const Color surfaceDark = Color(0xFF171424);     // Deep purple card
  static const Color cardDark = Color(0xFF171424);        // Deep purple card
  static const Color primaryDark = Color(0xFF9333EA);    // Vibrant Purple 500
  static const Color secondaryDark = Color(0xFF6366F1);  // Indigo 500
  static const Color accentDark = Color(0xFF34D399);     // Emerald 400
  static const Color textDark = Color(0xFFF5F3FF);       // Lavender-White
  static const Color textSecDark = Color(0xFFA78BFA);    // Violet-Muted
  static const Color borderDark = Color(0xFFF5F3FF);     // Clean bright borders

  // Lively creative highlights
  static const Color accentYellow = Color(0xFFFBBF24);   // Sunny Gold 400
  static const Color accentCoral = Color(0xFFF43F5E);    // Energetic Rose 500
  static const Color accentCyan = Color(0xFF06B6D4);     // Cyber Cyan 500

  // Neobrutalist Card Decoration Builder
  static BoxDecoration gameCardDecoration({
    required Color color,
    required Color borderColor,
    required Color shadowColor,
    double radius = radiusLarge,
    bool isSelected = false,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor, width: 2.5),
      boxShadow: isSelected
          ? []
          : [
              BoxShadow(
                color: shadowColor,
                offset: const Offset(4, 4),
                blurRadius: 0,
              ),
            ],
    );
  }

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
        error: Color(0xFFF43F5E),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textLight,
      ),
      textTheme: _textTheme(textLight, textSecLight),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: textLight,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: textLight),
      ),
      cardTheme: CardThemeData(
        color: cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          side: const BorderSide(color: borderLight, width: 2.5),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: borderLight,
        thickness: 2,
        space: 2,
      ),
      elevatedButtonTheme: _elevatedButtonTheme(primaryLight, borderLight),
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
        error: Color(0xFFF43F5E),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textDark,
      ),
      textTheme: _textTheme(textDark, textSecDark),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: textDark,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: textDark),
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          side: const BorderSide(color: borderDark, width: 2.5),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: borderDark,
        thickness: 2,
        space: 2,
      ),
      elevatedButtonTheme: _elevatedButtonTheme(primaryDark, borderDark),
      outlinedButtonTheme: _outlinedButtonTheme(textDark, borderDark),
      inputDecorationTheme: _inputDecorationTheme(cardDark, borderDark, primaryDark, textSecDark),
    );
  }

  // ─── SHARED BUILDERS ──────────────────────────────────

  static TextTheme _textTheme(Color mainColor, Color secColor) {
    return TextTheme(
      displayLarge: GoogleFonts.outfit(fontSize: 42, fontWeight: FontWeight.w900, color: mainColor, letterSpacing: -1.0, height: 1.1),
      displayMedium: GoogleFonts.outfit(fontSize: 34, fontWeight: FontWeight.w900, color: mainColor, letterSpacing: -0.8, height: 1.15),
      displaySmall: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w800, color: mainColor, letterSpacing: -0.5, height: 1.2),
      headlineLarge: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: mainColor, letterSpacing: -0.3, height: 1.25),
      headlineMedium: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: mainColor, height: 1.3),
      headlineSmall: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: mainColor, height: 1.3),
      titleLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: mainColor, height: 1.4),
      titleMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: secColor, height: 1.4),
      titleSmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: secColor, height: 1.4),
      bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: mainColor, height: 1.5),
      bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: secColor, height: 1.5),
      bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: secColor, height: 1.5),
      labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white, height: 1.4),
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme(Color bgColor, Color borderColor) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          side: BorderSide(color: borderColor, width: 2.5),
        ),
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5),
      ),
    );
  }

  static OutlinedButtonThemeData _outlinedButtonTheme(Color textColor, Color borderColor) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: textColor,
        side: BorderSide(color: borderColor, width: 2.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMedium)),
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5),
      ),
    );
  }

  static InputDecorationTheme _inputDecorationTheme(Color fillColor, Color borderColor, Color activeColor, Color hintColor) {
    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide(color: borderColor, width: 2.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide(color: borderColor, width: 2.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide(color: activeColor, width: 2.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: Color(0xFFF43F5E), width: 2.5),
      ),
      hintStyle: GoogleFonts.inter(color: hintColor.withOpacity(0.5), fontSize: 14, fontWeight: FontWeight.w500),
      labelStyle: GoogleFonts.inter(color: hintColor, fontSize: 14, fontWeight: FontWeight.w500),
    );
  }
}

/// Dotted and grid-lines drawing canvas background painter to enhance creative vibes
class SketchpadBackgroundPainter extends CustomPainter {
  final Color gridColor;
  final bool isDark;

  SketchpadBackgroundPainter({required this.gridColor, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor.withOpacity(isDark ? 0.05 : 0.04)
      ..strokeWidth = 1.0;

    const double step = 24.0;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
