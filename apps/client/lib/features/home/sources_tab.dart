import 'package:flutter/material.dart';

import '../documents/document_viewer_screen.dart';
import '../lens/lens_projection_screen.dart';
import '../photos/photo_viewer_screen.dart';
import '../presentations/presentation_viewer_screen.dart';
import '../projection/projection_screen.dart';
import '../videos/video_viewer_screen.dart';

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
  _SourceType(
    icon: Icons.photo_outlined,
    label: 'Photos',
    builder: (_) => const PhotoViewerScreen(),
  ),
  _SourceType(
    icon: Icons.play_circle_outline,
    label: 'Vidéos',
    builder: (_) => const VideoViewerScreen(),
  ),
  _SourceType(
    icon: Icons.description_outlined,
    label: 'Documents',
    builder: (_) => const DocumentViewerScreen(),
  ),
  _SourceType(
    icon: Icons.slideshow_outlined,
    label: 'Présentations',
    builder: (_) => const PresentationViewerScreen(),
  ),
  const _SourceType(icon: Icons.draw_outlined, label: 'Tableau blanc'),
];

/// Bibliothèque des sources de projection. « Écran », « Lentille », « Photos »,
/// « Vidéos », « Documents » et « Présentations » sont réellement implémentées
/// aujourd'hui ; les autres apparaissent grisées plutôt que masquées, pour
/// montrer la direction du produit sans prétendre qu'elles existent déjà (voir
/// docs/decisions-a-valider.md).
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
