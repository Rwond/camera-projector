import 'package:flutter/material.dart';

import '../lens/lens_projection_screen.dart';
import '../projection/projection_screen.dart';

class _SourceType {
  const _SourceType({
    required this.icon,
    required this.label,
    this.builder,
  });

  final IconData icon;
  final String label;
  final WidgetBuilder? builder;

  bool get available => builder != null;
}

final _sourceTypes = <_SourceType>[
  _SourceType(
    icon: Icons.cast,
    label: 'Écran',
    builder: (_) => const ProjectionScreen(),
  ),
  _SourceType(
    icon: Icons.wb_sunny_outlined,
    label: 'Lentille',
    builder: (_) => const LensProjectionScreen(),
  ),
  const _SourceType(icon: Icons.photo_camera_outlined, label: 'Caméra'),
  const _SourceType(icon: Icons.photo_outlined, label: 'Photos'),
  const _SourceType(icon: Icons.play_circle_outline, label: 'Vidéos'),
  const _SourceType(icon: Icons.description_outlined, label: 'Documents'),
  const _SourceType(icon: Icons.slideshow_outlined, label: 'Présentations'),
  const _SourceType(icon: Icons.draw_outlined, label: 'Tableau blanc'),
];

/// Bibliothèque des sources de projection. Seules « Écran » et « Lentille »
/// sont réellement implémentées aujourd'hui ; les autres apparaissent
/// grisées plutôt que masquées, pour montrer la direction du produit sans
/// prétendre qu'elles existent déjà (voir docs/decisions-a-valider.md).
class SourcesTab extends StatelessWidget {
  const SourcesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.25,
      ),
      itemCount: _sourceTypes.length,
      itemBuilder: (context, i) {
        final s = _sourceTypes[i];
        return Opacity(
          opacity: s.available ? 1 : 0.45,
          child: Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: s.available
                  ? () => Navigator.of(context).push(
                        MaterialPageRoute(builder: s.builder!),
                      )
                  : () => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${s.label} : pas encore implémenté.')),
                      ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(s.icon, color: theme.colorScheme.primary),
                    const SizedBox(height: 10),
                    Text(s.label, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      s.available ? 'Disponible' : 'À venir',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
