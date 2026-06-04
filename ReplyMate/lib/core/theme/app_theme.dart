import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Brand Colors ───────────────────────────────────────────────────────────
  // Keep one source of truth so all modules look structurally consistent.
  static const Color primary = Color(0xFF24389C);
  static const Color primaryContainer = Color(0xFF3F51B5);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF8F9FA);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF3F4F5);
  static const Color surfaceContainerHigh = Color(0xFFE7E8E9);
  static const Color onSurface = Color(0xFF191C1D);
  static const Color onSurfaceVariant = Color(0xFF454652);
  static const Color secondary = Color(0xFF006A6A);
  static const Color secondaryContainer = Color(0xFFB2DFDB);
  static const Color tertiary = Color(0xFF1565C0); // optional module highlight
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
        onSecondaryContainer: Color(0xFF004D4D),
        tertiary: tertiary,
        onTertiary: onPrimary,
        tertiaryContainer: Color(0xFFD9E8FF),
        onTertiaryContainer: Color(0xFF0D47A1),
        error: error,
        onError: onPrimary,
        errorContainer: Color(0xFFFFDAD6),
        onErrorContainer: Color(0xFF93000A),
        surface: surface,
        onSurface: onSurface,
        surfaceContainerLowest: surfaceContainerLowest,
        surfaceContainerLow: surfaceContainerLow,
        surfaceContainerHighest: Color(0xFFE1E3E4),
        outline: Color(0xFF757684),
        outlineVariant: outlineVariant,
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        inverseSurface: Color(0xFF2E3132),
        onInverseSurface: Color(0xFFF0F1F2),
        inversePrimary: Color(0xFF90A4FF),
      ),
      textTheme: GoogleFonts.manropeTextTheme().copyWith(
        bodyMedium: GoogleFonts.inter(fontSize: 14),
        bodySmall: GoogleFonts.inter(fontSize: 12),
        labelMedium: GoogleFonts.inter(fontSize: 12),
        labelSmall: GoogleFonts.inter(fontSize: 11),
      ),
      scaffoldBackgroundColor: surface,
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 0,
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: onPrimary,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
      ),
      cardTheme: CardThemeData(
        color: surfaceContainerLowest,
        elevation: 1.5,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary.withValues(alpha: 0.45);
          }
          return null;
        }),
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: Color(0xFF3B82F6), // primary
        onPrimary: Color(0xFFE5E7EB), // textPrimary
        primaryContainer: Color(0xFF1D4ED8), // primaryDark
        onPrimaryContainer: Color(0xFFE5E7EB),
        secondary: Color(0xFF3B82F6),
        onSecondary: Color(0xFFE5E7EB),
        secondaryContainer: Color(0xFF1D4ED8),
        onSecondaryContainer: Color(0xFFE5E7EB),
        tertiary: Color(0xFF3B82F6),
        onTertiary: Color(0xFFE5E7EB),
        tertiaryContainer: Color(0xFF1E293B),
        onTertiaryContainer: Color(0xFFE5E7EB),
        error: Color(0xFFEF4444), // error
        onError: Color(0xFFFFFFFF),
        errorContainer: Color(0xFF7F1D1D),
        onErrorContainer: Color(0xFFFFFFFF),
        surface: Color(0xFF0F172A), // bg
        onSurface: Color(0xFFE5E7EB), // textPrimary
        surfaceContainerLowest: Color(0xFF020617),
        surfaceContainerLow: Color(0xFF1E293B),
        surfaceContainerHighest: Color(0xFF374151), // divider
        outline: Color(0xFF9CA3AF), // textSecondary
        outlineVariant: Color(0xFF374151), // divider
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        inverseSurface: Color(0xFFE5E7EB),
        onInverseSurface: Color(0xFF0F172A),
        inversePrimary: Color(0xFF1D4ED8),
      ),
      textTheme: GoogleFonts.manropeTextTheme(ThemeData.dark().textTheme)
          .copyWith(
            bodyMedium: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFFE5E7EB),
            ),
            bodySmall: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF9CA3AF),
            ),
            labelMedium: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFFE5E7EB),
            ),
            labelSmall: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFFE5E7EB),
            ),
          ),
      scaffoldBackgroundColor: const Color(0xFF0F172A), // bg
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF0F172A), // bg
        foregroundColor: const Color(0xFFE5E7EB),
        elevation: 0,
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: const Color(0xFFE5E7EB),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF3B82F6), // primary
        foregroundColor: Color(0xFFFFFFFF),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E293B), // card
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF374151)), // divider
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF111827), // surface
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF374151)), // divider
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF374151)), // divider
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFF3B82F6),
            width: 1.4,
          ), // primary
        ),
        labelStyle: const TextStyle(color: Color(0xFF9CA3AF)), // textSecondary
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF3B82F6), // primary
          foregroundColor: const Color(0xFFFFFFFF),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF3B82F6), // primary
          side: const BorderSide(color: Color(0xFF3B82F6)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected))
            return const Color(0xFF3B82F6);
          return const Color(0xFF9CA3AF);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF3B82F6).withValues(alpha: 0.45);
          }
          return const Color(0xFF374151);
        }),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1E293B),
        selectedItemColor: Color(0xFF3B82F6),
        unselectedItemColor: Color(0xFF9CA3AF),
      ),
    );
  }
}
