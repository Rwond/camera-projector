import 'package:flutter/material.dart';

import '../devices/devices_service.dart';
import '../lens/lens_projection_screen.dart';
import '../projection/projection_screen.dart';
import '../projection/receiver_screen.dart';

/// Onglet d'accueil : une action principale claire plutôt qu'un tableau de
/// bord — conforme à l'esprit « priorité à l'action, pas aux statistiques ».
class HomeTab extends StatelessWidget {
  const HomeTab({super.key, required this.devicesService, required this.onOpenTab});

  final DevicesService devicesService;
  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.colorScheme.surfaceContainerHighest),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SWVERTEX CAMERA PROJECTOR',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Prêt à projeter quelque chose ?',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                'Trois prototypes réels à ce stade : écran vers navigateur, '
                'projection par lentille, et réception directe sans '
                'navigateur.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.cast,
                      label: 'Démarrer une projection',
                      sublabel: 'Mode B — écran vers navigateur',
                      primary: true,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ProjectionScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.devices_other,
                      label: 'Mes appareils',
                      sublabel: 'Gérer les appareils associés',
                      onTap: () => onOpenTab(3),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('Autres prototypes', style: theme.textTheme.titleMedium),
        const SizedBox(height: 10),
        _ListAction(
          icon: Icons.wb_sunny_outlined,
          title: 'Projection par lentille (Mode C)',
          subtitle: 'Affiche une image plein écran pour un montage optique externe.',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LensProjectionScreen()),
          ),
        ),
        _ListAction(
          icon: Icons.wifi_tethering,
          title: 'Recevoir une projection',
          subtitle: 'Reçoit un flux Mode B d\'un autre appareil, sans navigateur.',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ReceiverScreen()),
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final String sublabel;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = primary ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest;
    final fg = primary ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: fg),
              const SizedBox(height: 10),
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(color: fg),
              ),
              const SizedBox(height: 2),
              Text(
                sublabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: fg.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListAction extends StatelessWidget {
  const _ListAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
