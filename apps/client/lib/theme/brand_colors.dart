import 'package:flutter/material.dart';

/// Couleurs extraites du logo (packages/brand-assets/favicon/logo.png) par
/// échantillonnage des pixels : bleu/cyan de l'objectif, violet du faisceau
/// de projection, fond quasi noir. Ce sont les seules couleurs de marque ;
/// tout le reste de l'interface doit en dériver plutôt qu'introduire de
/// nouvelles teintes arbitraires.
abstract final class BrandColors {
  /// Bleu principal (anneau de l'objectif) — couleur de marque dominante.
  static const primary = Color(0xFF0A6CFF);

  /// Cyan (reflets de l'objectif, sous-titre « CAMERA ») — accent secondaire.
  static const cyan = Color(0xFF17C9FF);

  /// Violet (extrémité du faisceau, sous-titre « PROJECTOR ») — accent
  /// tertiaire, à réserver à un seul usage marquant par écran (ex. mode
  /// lentille) plutôt que diffusé partout.
  static const violet = Color(0xFF8B2FF7);

  /// Fond quasi noir du logo. Utilisé comme fond d'application : un thème
  /// sombre colle à l'identité de marque ET à l'usage réel (projection dans
  /// une pièce sombre), ce n'est pas qu'esthétique.
  static const ink = Color(0xFF05070D);

  /// Surface légèrement plus claire que [ink] pour les cartes/panneaux —
  /// dérivée du fond de marque, pas une nouvelle teinte.
  static const surface = Color(0xFF11151F);
  static const surfaceAlt = Color(0xFF1A2030);

  // Couleurs fonctionnelles (états), volontairement neutres et distinctes des
  // couleurs de marque ci-dessus : elles signalent un état (actif/erreur),
  // pas l'identité visuelle.
  static const success = Color(0xFF34D399);
  static const warning = Color(0xFFFBBF24);
  static const danger = Color(0xFFF87171);
}
