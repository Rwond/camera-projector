import 'package:flutter/material.dart';

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

  return base.copyWith(
    scaffoldBackgroundColor: BrandColors.ink,
    textTheme: base.textTheme.copyWith(
      // Les titres reprennent l'esprit « géométrique et espacé » du
      // logotype ; le corps de texte reste au réglage par défaut pour
      // rester aussi lisible que possible.
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    ),
    appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}
