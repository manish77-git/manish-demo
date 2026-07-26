import 'package:flutter/material.dart';

/// DrawBattle — Curated color palette for a playful, warm game aesthetic.
/// No generic blues/reds — every color is hand-picked for a cohesive indie-game feel.
class AppColors {
  AppColors._();

  // ─── LIGHT MODE ────────────────────────────────────────
  static const Color bgLight = Color(0xFFFFF8F0);          // Warm cream
  static const Color surfaceLight = Color(0xFFFFF1E6);     // Peach tint
  static const Color cardLight = Color(0xFFFFFFFF);        // Pure white cards
  static const Color primaryLight = Color(0xFFFF6B6B);     // Coral Red
  static const Color secondaryLight = Color(0xFF4ECDC4);   // Teal
  static const Color accentLight = Color(0xFFFFE66D);      // Sunny Yellow
  static const Color textPrimaryLight = Color(0xFF2D3436); // Near-black
  static const Color textSecondaryLight = Color(0xFF636E72); // Warm gray
  static const Color borderLight = Color(0xFFE8DDD3);      // Warm border
  static const Color dividerLight = Color(0xFFF0E6DC);     // Subtle divider

  // ─── DARK MODE ─────────────────────────────────────────
  static const Color bgDark = Color(0xFF1A1B2E);           // Deep navy
  static const Color surfaceDark = Color(0xFF222344);      // Navy surface
  static const Color cardDark = Color(0xFF2A2B4A);         // Elevated card
  static const Color primaryDark = Color(0xFFFF8A8A);      // Soft coral
  static const Color secondaryDark = Color(0xFF6EDCD5);    // Bright teal
  static const Color accentDark = Color(0xFFFFE88A);       // Soft yellow
  static const Color textPrimaryDark = Color(0xFFF5F0EB);  // Warm white
  static const Color textSecondaryDark = Color(0xFF9BA3AF); // Muted text
  static const Color borderDark = Color(0xFF3D3E5C);       // Subtle border
  static const Color dividerDark = Color(0xFF33345A);      // Dark divider

  // ─── SHARED ACCENT COLORS ─────────────────────────────
  static const Color coral = Color(0xFFFF6B6B);
  static const Color teal = Color(0xFF4ECDC4);
  static const Color sunny = Color(0xFFFFE66D);
  static const Color lavender = Color(0xFFA78BFA);
  static const Color mint = Color(0xFF6BCB77);
  static const Color peach = Color(0xFFFFB4A2);
  static const Color skyBlue = Color(0xFF74C0FC);
  static const Color rose = Color(0xFFFF85A1);
  static const Color orange = Color(0xFFFF922B);

  // ─── GRADE COLORS ──────────────────────────────────────
  static const Color gradeS = Color(0xFFFFD700);  // Gold
  static const Color gradeA = Color(0xFF2ECC71);  // Emerald
  static const Color gradeB = Color(0xFF3498DB);  // Sky blue
  static const Color gradeC = Color(0xFFF39C12);  // Amber
  static const Color gradeD = Color(0xFFE67E22);  // Orange
  static const Color gradeF = Color(0xFFE74C3C);  // Red

  static Color gradeColor(String grade) {
    switch (grade.toUpperCase()) {
      case 'S': return gradeS;
      case 'A': return gradeA;
      case 'B': return gradeB;
      case 'C': return gradeC;
      case 'D': return gradeD;
      default: return gradeF;
    }
  }

  // ─── CANVAS PRESET COLORS ─────────────────────────────
  static const List<Color> canvasPresets = [
    Color(0xFF2D3436), // Near black
    Color(0xFF636E72), // Gray
    Color(0xFFFF6B6B), // Coral
    Color(0xFFFF922B), // Orange
    Color(0xFFFFE66D), // Yellow
    Color(0xFF6BCB77), // Green
    Color(0xFF4ECDC4), // Teal
    Color(0xFF74C0FC), // Sky
    Color(0xFF5C7CFA), // Indigo
    Color(0xFFA78BFA), // Lavender
    Color(0xFFFF85A1), // Pink
    Color(0xFF8B5E3C), // Brown
    Colors.white,
  ];

  // ─── CONFETTI COLORS ───────────────────────────────────
  static const List<Color> confetti = [
    coral, teal, sunny, lavender, mint, peach, skyBlue, rose, orange,
  ];

  // ─── HELPERS ───────────────────────────────────────────

  /// Get themed color based on brightness
  static Color primary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? primaryDark : primaryLight;

  static Color secondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? secondaryDark : secondaryLight;

  static Color textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textPrimaryDark : textPrimaryLight;

  static Color textSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textSecondaryDark : textSecondaryLight;

  static Color card(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? cardDark : cardLight;

  static Color bg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? bgDark : bgLight;

  static Color border(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? borderDark : borderLight;

  static Color surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? surfaceDark : surfaceLight;
}
