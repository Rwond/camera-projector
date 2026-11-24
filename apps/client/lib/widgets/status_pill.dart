import 'package:flutter/material.dart';

import '../theme/brand_colors.dart';

/// Pastille d'état compacte (point + libellé), utilisée partout où un état
/// réel doit être visible d'un coup d'œil (appareil actif/révoqué, capture en
/// cours/arrêtée...). Volontairement limité à des états qui existent pour de
/// vrai dans l'app — pas de statut inventé ("en ligne", "qualité" etc. tant
/// que rien ne les mesure réellement).
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.tone});

  final String label;
  final StatusTone tone;

  Color _color() => switch (tone) {
    StatusTone.positive => BrandColors.success,
    StatusTone.neutral => Colors.grey,
    StatusTone.warning => BrandColors.warning,
    StatusTone.negative => BrandColors.danger,
  };

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

enum StatusTone { positive, neutral, warning, negative }
