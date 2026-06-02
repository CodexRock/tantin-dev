import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tantin_flutter/core/theme/tokens.dart';

abstract class TantinTheme {
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.instrumentSansTextTheme();
    final displayFont = GoogleFonts.fraunces().fontFamily;

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: TantinColors.ivorySurface,
      colorScheme: const ColorScheme.light(
        primary: TantinColors.majorelle,
        secondary: TantinColors.saffron,
        onSecondary: Colors.white,
        error: TantinColors.danger,
        surface: TantinColors.ivorySurface,
        onSurface: TantinColors.ink,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          fontFamily: displayFont,
        ),
        displayMedium: baseTextTheme.displayMedium?.copyWith(
          fontFamily: displayFont,
        ),
        displaySmall: baseTextTheme.displaySmall?.copyWith(
          fontFamily: displayFont,
        ),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(
          fontFamily: displayFont,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          fontFamily: displayFont,
        ),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(
          fontFamily: displayFont,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(fontFamily: displayFont),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: TantinColors.ivorySurface,
        foregroundColor: TantinColors.ink,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
