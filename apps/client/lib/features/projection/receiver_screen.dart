import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/device_name.dart';
import 'discovery_service.dart';
import 'mjpeg_viewer_screen.dart';
import 'pairing_service.dart';

/// Fait de cet appareil (PC, TV, etc.) un récepteur : visible sur le réseau
/// local, il affiche une demande d'autorisation dès qu'un émetteur (le
/// prototype labo du mode B) souhaite s'y connecter, puis projette
/// directement dans l'application — sans navigateur — une fois acceptée.
class ReceiverScreen extends StatefulWidget {
  const ReceiverScreen({
    super.key,
    this.pairingServer,
    this.deviceName,
    this.enableAnnouncer = true,
  });

  final PairingServer? pairingServer;
  final String? deviceName;

  /// Désactivé dans les tests : la diffusion UDP réelle n'a rien à faire
  /// dans une suite de tests et son comportement dépend du réseau de la
  /// machine qui l'exécute.
  final bool enableAnnouncer;

  @override
  State<ReceiverScreen> createState() => _ReceiverScreenState();
}

class _ReceiverScreenState extends State<ReceiverScreen> {
  late final PairingServer _server = widget.pairingServer ?? PairingServer();
  late final String _deviceName = widget.deviceName ?? defaultDeviceName();
  StreamSubscription<PendingPairingRequest>? _subscription;
  ReceiverAnnouncer? _announcer;
  int? _port;
  String? _error;

  @override
  void initState() {
    super.initState();
    _subscription = _server.incomingRequests.listen(_onIncomingRequest);
    _start();
  }

  Future<void> _start() async {
    try {
      final port = await _server.start();
      if (!mounted) return;
      setState(() => _port = port);
      if (widget.enableAnnouncer) {
        final announcer = ReceiverAnnouncer(name: _deviceName, pairPort: port);
        _announcer = announcer;
        await announcer.start();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Impossible de démarrer le récepteur : $e');
      }
    }
  }

  Future<void> _onIncomingRequest(PendingPairingRequest pending) async {
    final accepted = await _confirm(pending.request);
    pending.respond(accepted);
    if (accepted && mounted) {
      final uri = Uri.tryParse(pending.request.streamUrl);
      if (uri == null) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MjpegViewerScreen(
            streamUri: uri,
            sourceName: pending.request.fromName,
          ),
        ),
      );
    }
  }

  Future<bool> _confirm(PairingRequest request) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Demande de projection'),
        content: Text(
          '« ${request.fromName} » souhaite projeter sur cet écran. Accepter ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Refuser'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Accepter'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _server.stop();
    _announcer?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Recevoir une projection (labo)')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.wifi_tethering,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text('Visible sur le réseau sous le nom :', style: theme.textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text(_deviceName, style: theme.textTheme.titleLarge),
                const SizedBox(height: 24),
                if (_error != null)
                  Text(_error!, style: TextStyle(color: theme.colorScheme.error))
                else if (_port == null)
                  const CircularProgressIndicator()
                else
                  const Text('En attente d\'une demande de connexion…'),
                const SizedBox(height: 24),
                Card(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Limites du prototype', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        const Text(
                          '• Découverte par diffusion Wi-Fi locale uniquement '
                          '(même réseau, pas de routage entre sous-réseaux).',
                        ),
                        const Text(
                          '• Ni Bluetooth ni câble : voir '
                          'docs/decisions-a-valider.md.',
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
