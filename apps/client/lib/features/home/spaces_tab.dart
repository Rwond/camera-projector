import 'package:flutter/material.dart';

/// Onglet Spaces : la fonctionnalité « espace partagé multi-appareils » du
/// nouveau design n'est pas encore construite. Plutôt que de simuler une
/// fausse liste d'espaces, cet écran l'annonce honnêtement et explique ce
/// qui existe déjà à la place (connexion directe, mode B/C).
class SpacesTab extends StatelessWidget {
  const SpacesTab({super.key, required this.onOpenSources});

  final VoidCallback onOpenSources;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(Icons.hub_outlined, color: theme.colorScheme.primary, size: 28),
            ),
            const SizedBox(height: 18),
            Text(
              'Les Spaces arrivent bientôt',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Un Space réunira plusieurs appareils et sources dans une même '
              'session partagée. Ce n\'est pas encore construit — voir '
              'docs/decisions-a-valider.md pour l\'état du chantier.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onOpenSources,
              icon: const Icon(Icons.cast),
              label: const Text('Utiliser une projection directe'),
            ),
          ],
        ),
      ),
    );
  }
}
