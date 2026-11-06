import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'projection_service.dart';

/// Écran de test "labo" du mode B : capture l'écran Android et le diffuse en MJPEG
/// sur le réseau local. Ce n'est pas encore l'implémentation finale du mode B.
class ProjectionScreen extends StatefulWidget {
  const ProjectionScreen({
    super.key,
    this.service = const ProjectionService(),
    this.isAndroidOverride,
  });

  final ProjectionService service;

  /// Permet aux tests de simuler Android sans toucher aux variables de debug globales.
  final bool? isAndroidOverride;

  @override
  State<ProjectionScreen> createState() => _ProjectionScreenState();
}

class _ProjectionScreenState extends State<ProjectionScreen> {
  ProjectionStatus? _status;
  String? _error;
  bool _busy = false;

  bool get _isAndroid =>
      widget.isAndroidOverride ??
      (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);

  bool get _running => _status?.running ?? false;

  @override
  void initState() {
    super.initState();
    if (_isAndroid) {
      unawaited(_refreshStatus());
    }
  }

  Future<void> _refreshStatus() async {
    try {
      final status = await widget.service.status();
      if (!mounted) return;
      setState(() {
        _status = status;
        _error = status.error;
      });
    } on MissingPluginException {
      _showUnsupported();
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message ?? e.code);
    }
  }

  void _showUnsupported() {
    if (!mounted) return;
    setState(
      () => _error = 'Ce prototype est disponible uniquement sur Android.',
    );
  }

  Future<void> _start() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.service.start();
      await _waitForRunning();
    } on MissingPluginException {
      _showUnsupported();
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message ?? e.code);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _waitForRunning() async {
    for (var attempt = 0; attempt < 20; attempt++) {
      final status = await widget.service.status();
      if (!mounted) return;
      setState(() {
        _status = status;
        _error = status.error;
      });
      if (status.running) return;
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
  }

  Future<void> _stop() async {
    setState(() => _busy = true);
    try {
      await widget.service.stop();
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await _refreshStatus();
    } on MissingPluginException {
      _showUnsupported();
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message ?? e.code);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copyUrl() async {
    final url = _status?.url;
    if (url == null) return;
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Adresse copiée.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test de projection (labo)')),
      body: !_isAndroid ? _buildUnsupported() : _buildAndroidContent(context),
    );
  }

  Widget _buildUnsupported() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Ce prototype de capture d\'écran est disponible uniquement sur Android.\n\n'
          'iOS, Windows et macOS nécessiteront chacun leur module natif '
          '(ReplayKit, Windows Graphics Capture, ScreenCaptureKit).',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildAndroidContent(BuildContext context) {
    final url = _status?.url;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _running ? Icons.cast_connected : Icons.cast,
                      color: _running
                          ? Colors.green
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _running ? 'Capture active' : 'Capture arrêtée',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                if (_running && url != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Ouvre cette adresse sur le récepteur :',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    url,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontFamily: 'monospace',
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _copyUrl,
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copier l\'adresse'),
                  ),
                ] else if (_running) ...[
                  const SizedBox(height: 8),
                  const Text('Serveur actif, adresse réseau indisponible.'),
                ],
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _busy ? null : (_running ? _stop : _start),
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(_running ? Icons.stop : Icons.play_arrow),
                  label: Text(
                    _running ? 'Arrêter la capture' : 'Démarrer la capture',
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Card(
            color: theme.colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        Text('Mode d\'emploi', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        const _Step(
          number: 1,
          text: 'Connecte le téléphone et le PC/TV au même réseau Wi-Fi.',
        ),
        const _Step(
          number: 2,
          text: 'Démarre la capture et accepte la demande Android.',
        ),
        const _Step(
          number: 3,
          text:
              'Ouvre l\'adresse affichée dans un navigateur sur le récepteur.',
        ),
        const _Step(
          number: 4,
          text:
              'En USB uniquement : adb reverse tcp:8080 tcp:8080, puis http://localhost:8080/ sur le PC.',
        ),
        const SizedBox(height: 20),
        Card(
          color: theme.colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Limites du prototype', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                const Text('• Android uniquement, sans son.'),
                const Text('• Environ 10 images/s, JPEG 720p.'),
                const Text(
                  '• Pas encore de Miracast/DLNA : le mode B final reste à définir.',
                ),
                const Text(
                  '• La capture s\'arrête si Android révoque l\'autorisation.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            child: Text('$number', style: const TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
