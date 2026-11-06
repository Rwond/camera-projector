import 'package:flutter/material.dart';
import '../auth/auth_service.dart';
import '../devices/devices_screen.dart';
import '../devices/devices_service.dart';
import '../projection/projection_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.authService,
    required this.devicesService,
    required this.onLoggedOut,
  });

  final AuthService authService;
  final DevicesService devicesService;
  final VoidCallback onLoggedOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SWVERTEX'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () async {
              await authService.logout();
              onLoggedOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Trois modes de projection : lentille, module USB-C, projecteur Wi-Fi.',
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.devices),
              label: const Text('Mes appareils'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        DevicesScreen(devicesService: devicesService),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.cast),
              label: const Text('Tester la projection (labo)'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProjectionScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
