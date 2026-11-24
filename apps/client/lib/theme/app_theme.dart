import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'brand_colors.dart';

/// Thème unique de l'application (sombre uniquement).
///
/// Justification : l'identité de marque (logo) est conçue sur fond noir, et
/// l'app sert surtout pendant une séance de projection — un thème clair
/// éblouirait l'utilisateur et la pièce. Un seul thème cohérent plutôt que
/// deux (clair/sombre) évite aussi les incohérences de contraste entre
/// écrans pendant qu'une partie des modules (modes A/B/C) reste à construire.
ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: BrandColors.primary,
    brightness: Brightness.dark,
  ).copyWith(
    primary: BrandColors.primary,
    onPrimary: Colors.white,
    secondary: BrandColors.cyan,
    onSecondary: Colors.black,
    tertiary: BrandColors.violet,
    onTertiary: Colors.white,
    surface: BrandColors.ink,
  );

  final base = ThemeData(colorScheme: colorScheme, useMaterial3: true);

  // Corps de texte en Inter (très lisible dans une pièce sombre), titres en
  // Space Grotesk (plus géométrique, fait écho au tracé du logo) — deux
  // familles de Google Fonts embarquées, jamais de dépendance réseau au
  // runtime (voir pubspec : google_fonts télécharge puis met en cache les
  // fichiers une seule fois).
  final textTheme = GoogleFonts.interTextTheme(base.textTheme);
  final displayTheme = GoogleFonts.spaceGroteskTextTheme(base.textTheme);

  return base.copyWith(
    scaffoldBackgroundColor: BrandColors.ink,
    textTheme: textTheme.copyWith(
      headlineSmall: displayTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      headlineMedium: displayTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleLarge: displayTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: displayTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: displayTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      titleTextStyle: displayTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: BrandColors.surface,
      indicatorColor: colorScheme.primary.withValues(alpha: 0.18),
      labelTextStyle: WidgetStatePropertyAll(
        textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      height: 64,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
    ),
    cardTheme: base.cardTheme.copyWith(
      elevation: 0,
      color: BrandColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: BrandColors.surfaceAlt),
      ),
    ),
  );
}
