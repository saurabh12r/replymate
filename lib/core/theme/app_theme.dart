import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Brand Colors (Stitch: "Precision Architect" Design System) ──
  static const Color primary = Color(0xFFFF8C00);
  static const Color primaryContainer = Color(0xFFFFA726);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF8F9FA);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF3F4F5);
  static const Color surfaceContainerHigh = Color(0xFFE7E8E9);
  static const Color onSurface = Color(0xFF191C1D);
  static const Color onSurfaceVariant = Color(0xFF454652);
  static const Color secondary = Color(0xFF006A6A);
  static const Color secondaryContainer = Color(0xFF90EFEF);
  static const Color outlineVariant = Color(0xFFC5C5D4);
  static const Color error = Color(0xFFBA1A1A);

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: primaryContainer,
        onPrimaryContainer: Color(0xFFCACFFF),
        secondary: secondary,
        onSecondary: onPrimary,
        secondaryContainer: secondaryContainer,
        onSecondaryContainer: Color(0xFF006E6E),
        tertiary: Color(0xFF004B4B),
        onTertiary: onPrimary,
        tertiaryContainer: Color(0xFF006565),
        onTertiaryContainer: Color(0xFF5FE5E5),
        error: error,
        onError: onPrimary,
        errorContainer: Color(0xFFFFDAD6),
        onErrorContainer: Color(0xFF93000A),
        surface: surface,
        onSurface: onSurface,
        surfaceContainerHighest: Color(0xFFE1E3E4),
        outline: Color(0xFF757684),
        outlineVariant: outlineVariant,
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        inverseSurface: Color(0xFF2E3132),
        onInverseSurface: Color(0xFFF0F1F2),
        inversePrimary: Color(0xFFFFCC80),
      ),
      textTheme: GoogleFonts.manropeTextTheme().copyWith(
        bodyMedium: GoogleFonts.inter(fontSize: 14),
        bodySmall: GoogleFonts.inter(fontSize: 12),
        labelMedium: GoogleFonts.inter(fontSize: 12),
        labelSmall: GoogleFonts.inter(fontSize: 11),
      ),
      scaffoldBackgroundColor: surface,
    );
  }
}
