import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../devices/devices_screen.dart';
import '../devices/devices_service.dart';
import 'home_tab.dart';
import 'settings_tab.dart';
import 'spaces_tab.dart';
import 'sources_tab.dart';

/// Coquille de navigation de l'app connectée : Accueil / Spaces / Sources /
/// Appareils / Paramètres — cinq destinations, comme dans la maquette, mais
/// chacune ne montre que des fonctionnalités réelles (ou l'annonce
/// honnêtement quand ce n'est pas encore le cas, voir spaces_tab.dart).
class HomeScreen extends StatefulWidget {
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
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _titles = ['Accueil', 'Spaces', 'Sources', 'Appareils', 'Paramètres'];

  void _openTab(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeTab(devicesService: widget.devicesService, onOpenTab: _openTab),
      const SpacesTab(),
      const SourcesTab(),
      DevicesScreen(devicesService: widget.devicesService),
      SettingsTab(authService: widget.authService, onLoggedOut: widget.onLoggedOut),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _openTab,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Accueil'),
          NavigationDestination(icon: Icon(Icons.hub_outlined), selectedIcon: Icon(Icons.hub), label: 'Spaces'),
          NavigationDestination(icon: Icon(Icons.video_library_outlined), selectedIcon: Icon(Icons.video_library), label: 'Sources'),
          NavigationDestination(icon: Icon(Icons.devices_outlined), selectedIcon: Icon(Icons.devices), label: 'Appareils'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Réglages'),
        ],
      ),
    );
  }
}
