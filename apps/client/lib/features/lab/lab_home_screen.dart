import 'package:flutter/material.dart';

import '../lens/lens_projection_screen.dart';
import '../projection/projection_screen.dart';

/// Accueil des builds labo : donne un accès direct aux prototypes B et C
/// sans passer par l'authentification ni par l'écran d'accueil normal.
class LabHomeScreen extends StatelessWidget {
  const LabHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Labo projection')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Choisir un mode',
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Build labo : accès direct, sans authentification.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ProjectionScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.cast),
                  label: const Text('Mode B — écran vers navigateur'),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const LensProjectionScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.wb_sunny_outlined),
                  label: const Text('Mode C — projection par lentille'),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rappel', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        const Text(
                          'Le mode C est un prototype optique : il affiche une '
                          'image sur l\'écran et nécessite une lentille externe '
                          'pour projeter sur un mur.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
