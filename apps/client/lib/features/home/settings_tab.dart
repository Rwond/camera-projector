import 'package:flutter/material.dart';

import '../auth/auth_service.dart';

/// Onglet Paramètres : uniquement des réglages réels. Pas de bascule
/// thème clair/sombre (l'app est volontairement sombre uniquement, voir
/// theme/app_theme.dart) ni de case à cocher qui ne branche sur rien.
class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key, required this.authService, required this.onLoggedOut});

  final AuthService authService;
  final VoidCallback onLoggedOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Compte', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Déconnexion'),
            onTap: () async {
              await authService.logout();
              onLoggedOut();
            },
          ),
        ),
        const SizedBox(height: 20),
        Text('Apparence', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Thème sombre uniquement, assumé : l\'app sert pendant des '
              'séances de projection en pièce sombre, et un thème clair '
              'serait contre-productif.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('À propos', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        const Card(child: _AboutTile()),
      ],
    );
  }
}

class _AboutTile extends StatelessWidget {
  const _AboutTile();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.info_outline),
      title: const Text('SWVERTEX CAMERA PROJECTOR'),
      subtitle: const Text('Client — prototypes labo en cours de construction'),
    );
  }
}
