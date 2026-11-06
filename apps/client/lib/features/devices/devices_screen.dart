import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import 'devices_service.dart';

const _deviceTypes = ['PHONE', 'COMPUTER', 'RECEIVER', 'ACCESSORY_CONTROLLER'];
const _platforms = ['ANDROID', 'IOS', 'WINDOWS', 'MACOS', 'WEB'];

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key, required this.devicesService});

  final DevicesService devicesService;

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  late Future<List<Device>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.devicesService.list();
  }

  void _reload() {
    setState(() => _future = widget.devicesService.list());
  }

  Future<void> _revoke(String id) async {
    await widget.devicesService.revoke(id);
    _reload();
  }

  Future<void> _openRegisterDialog() async {
    String type = _deviceTypes.first;
    String platform = _platforms.first;
    final modelController = TextEditingController();

    final created = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Associer cet appareil'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: _deviceTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setDialogState(() => type = v!),
              ),
              DropdownButtonFormField<String>(
                initialValue: platform,
                decoration: const InputDecoration(labelText: 'Plateforme'),
                items: _platforms.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (v) => setDialogState(() => platform = v!),
              ),
              TextField(
                controller: modelController,
                decoration: const InputDecoration(labelText: 'Modèle (optionnel)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Associer')),
          ],
        ),
      ),
    );

    if (created == true) {
      try {
        await widget.devicesService.register(type: type, platform: platform, model: modelController.text);
        _reload();
      } on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Échec : ${e.message}')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes appareils')),
      body: FutureBuilder<List<Device>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }
          final devices = snapshot.data ?? [];
          if (devices.isEmpty) {
            return const Center(child: Text('Aucun appareil associé pour le moment.'));
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.builder(
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index];
                return ListTile(
                  leading: const Icon(Icons.devices),
                  title: Text(device.model?.isNotEmpty == true ? device.model! : device.type),
                  subtitle: Text('${device.platform} · ${device.status}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.link_off),
                    tooltip: 'Dissocier',
                    onPressed: () => _revoke(device.id),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openRegisterDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
