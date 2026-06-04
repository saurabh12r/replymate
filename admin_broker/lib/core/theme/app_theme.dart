import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const String _fontFamily = 'system-ui';

  static TextStyle _ts(
    Color color,
    double fontSize, {
    FontWeight fontWeight = FontWeight.w400,
    double letterSpacing = 0,
    double? height,
  }) {
    return TextStyle(
      fontFamily: _fontFamily,
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  // Brand Colors
  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF9D97FF);
  static const Color primaryDark = Color(0xFF4A42D6);
  static const Color accentColor = Color(0xFF00D4AA);
  static const Color accentLight = Color(0xFF4DFFDA);
  static const Color warningColor = Color(0xFFFF9F43);
  static const Color errorColor = Color(0xFFFF6B6B);
  static const Color successColor = Color(0xFF51CF66);
  static const Color infoColor = Color(0xFF339AF0);

  // Dark Theme Surface Colors
  static const Color darkBackground = Color(0xFF0F0E17);
  static const Color darkSurface = Color(0xFF1A1928);
  static const Color darkCard = Color(0xFF22213A);
  static const Color darkCardHover = Color(0xFF2A2845);
  static const Color darkBorder = Color(0xFF2E2D4A);
  static const Color darkTextPrimary = Color(0xFFEEEEF7);
  static const Color darkTextSecondary = Color(0xFF8B8AAD);

  // Light Theme Surface Colors
  static const Color lightBackground = Color(0xFFF5F4FF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE8E7FF);
  static const Color lightTextPrimary = Color(0xFF1A1928);
  static const Color lightTextSecondary = Color(0xFF6B6A8D);

  // Gradient definitions
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, Color(0xFF9D63FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentColor, Color(0xFF00A3FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [warningColor, Color(0xFFFFCB43)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient errorGradient = LinearGradient(
    colors: [errorColor, Color(0xFFFF4E9C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static TextTheme _textThemeDark() {
    return ThemeData(brightness: Brightness.dark, useMaterial3: true).textTheme.copyWith(
      displayLarge: _ts(darkTextPrimary, 32, fontWeight: FontWeight.w700),
      displayMedium: _ts(darkTextPrimary, 24, fontWeight: FontWeight.w700),
      headlineLarge: _ts(darkTextPrimary, 20, fontWeight: FontWeight.w600),
      headlineMedium: _ts(darkTextPrimary, 18, fontWeight: FontWeight.w600),
      titleLarge: _ts(darkTextPrimary, 16, fontWeight: FontWeight.w600),
      titleMedium: _ts(darkTextPrimary, 14, fontWeight: FontWeight.w500),
      bodyLarge: _ts(darkTextSecondary, 14),
      bodyMedium: _ts(darkTextSecondary, 13),
      bodySmall: _ts(darkTextSecondary, 12),
      labelLarge: _ts(
        darkTextPrimary,
        14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
    );
  }

  static TextTheme _textThemeLight() {
    return ThemeData(brightness: Brightness.light, useMaterial3: true).textTheme.copyWith(
      displayLarge: _ts(lightTextPrimary, 32, fontWeight: FontWeight.w700),
      displayMedium: _ts(lightTextPrimary, 24, fontWeight: FontWeight.w700),
      headlineLarge: _ts(lightTextPrimary, 20, fontWeight: FontWeight.w600),
      headlineMedium: _ts(lightTextPrimary, 18, fontWeight: FontWeight.w600),
      titleLarge: _ts(lightTextPrimary, 16, fontWeight: FontWeight.w600),
      titleMedium: _ts(lightTextPrimary, 14, fontWeight: FontWeight.w500),
      bodyLarge: _ts(lightTextSecondary, 14),
      bodyMedium: _ts(lightTextSecondary, 13),
      bodySmall: _ts(lightTextSecondary, 12),
      labelLarge: _ts(
        lightTextPrimary,
        14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    final buttonLabel = _ts(Colors.white, 14, fontWeight: FontWeight.w600);
    return ThemeData(
      useMaterial3: true,
      fontFamily: _fontFamily,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        surface: darkSurface,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: darkTextPrimary,
      ),
      scaffoldBackgroundColor: darkBackground,
      cardColor: darkCard,
      textTheme: _textThemeDark(),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          textStyle: buttonLabel,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: _ts(primaryColor, 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: _ts(primaryColor, 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor),
        ),
        hintStyle: _ts(darkTextSecondary, 14),
        labelStyle: _ts(darkTextSecondary, 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dividerTheme: const DividerThemeData(
        color: darkBorder,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkCard,
        selectedColor: primaryColor.withOpacity(0.3),
        labelStyle: _ts(darkTextSecondary, 12),
        side: const BorderSide(color: darkBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkCard,
        contentTextStyle: _ts(darkTextPrimary, 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: _ts(darkTextPrimary, 18, fontWeight: FontWeight.w600),
      ),
    );
  }

  // Light Theme
  static ThemeData get lightTheme {
    final buttonLabel = _ts(Colors.white, 14, fontWeight: FontWeight.w600);
    return ThemeData(
      useMaterial3: true,
      fontFamily: _fontFamily,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        surface: lightSurface,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: lightTextPrimary,
      ),
      scaffoldBackgroundColor: lightBackground,
      cardColor: lightCard,
      textTheme: _textThemeLight(),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          textStyle: buttonLabel,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: _ts(primaryColor, 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: _ts(primaryColor, 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor),
        ),
        hintStyle: _ts(lightTextSecondary, 14),
        labelStyle: _ts(lightTextSecondary, 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dividerTheme: const DividerThemeData(
        color: lightBorder,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: lightBackground,
        selectedColor: primaryColor.withOpacity(0.15),
        labelStyle: _ts(lightTextSecondary, 12),
        side: const BorderSide(color: lightBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: lightCard,
        contentTextStyle: _ts(lightTextPrimary, 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: _ts(lightTextPrimary, 18, fontWeight: FontWeight.w600),
      ),
    );
  }
}
