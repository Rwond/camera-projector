import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/device_name.dart';
import 'discovery_service.dart';
import 'dlna_service.dart';
import 'pairing_service.dart';
import 'projection_service.dart';

/// Écran de test "labo" du mode B : capture l'écran Android et le diffuse en MJPEG
/// sur le réseau local. Ce n'est pas encore l'implémentation finale du mode B.
class ProjectionScreen extends StatefulWidget {
  const ProjectionScreen({
    super.key,
    this.service = const ProjectionService(),
    this.isAndroidOverride,
    this.pairingClient = const PairingClient(),
    this.enableScanning = true,
    this.receiversOverride,
    this.dlnaService = const DlnaCastService(),
  });

  final ProjectionService service;

  /// Permet aux tests de simuler Android sans toucher aux variables de debug globales.
  final bool? isAndroidOverride;

  final PairingClient pairingClient;

  /// Désactivé dans les tests : la découverte UDP réelle dépend du réseau de
  /// la machine qui exécute la suite.
  final bool enableScanning;

  /// Liste de récepteurs à afficher telle quelle (tests), à la place de la
  /// découverte réseau réelle.
  final List<DiscoveredReceiver>? receiversOverride;

  final DlnaCastService dlnaService;

  @override
  State<ProjectionScreen> createState() => _ProjectionScreenState();
}

class _ProjectionScreenState extends State<ProjectionScreen> {
  ProjectionStatus? _status;
  String? _error;
  bool _busy = false;

  ReceiverScanner? _scanner;
  StreamSubscription<List<DiscoveredReceiver>>? _scanSubscription;
  List<DiscoveredReceiver> _receivers = const [];
  DiscoveredReceiver? _connectingTo;
  String? _connectError;
  DiscoveredReceiver? _connectedTo;

  bool? _accessibilityEnabled;
  bool _remoteControlEnabled = false;
  bool _remoteControlBusy = false;

  bool _dlnaSearching = false;
  String? _dlnaError;
  List<DlnaRenderer> _dlnaRenderers = const [];
  DlnaRenderer? _dlnaCasting;
  DlnaRenderer? _dlnaCastedTo;

  bool get _isAndroid =>
      widget.isAndroidOverride ??
      (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);

  bool get _running => _status?.running ?? false;

  @override
  void initState() {
    super.initState();
    if (_isAndroid) {
      unawaited(_refreshStatus());
      unawaited(_refreshRemoteControlStatus());
    }
    if (widget.receiversOverride != null) {
      _receivers = widget.receiversOverride!;
    } else if (widget.enableScanning) {
      unawaited(_startScanning());
    }
  }

  Future<void> _startScanning() async {
    final scanner = ReceiverScanner();
    _scanner = scanner;
    try {
      await scanner.start();
      _scanSubscription = scanner.receivers.listen((list) {
        if (mounted) setState(() => _receivers = list);
      });
    } catch (_) {
      // Découverte indisponible sur ce réseau : la connexion directe reste
      // simplement invisible, le flux navigateur habituel reste utilisable.
    }
  }

  Future<void> _connectTo(DiscoveredReceiver receiver) async {
    final status = _status;
    if (status?.ip == null || status?.port == null) return;
    setState(() {
      _connectingTo = receiver;
      _connectError = null;
      _connectedTo = null;
    });
    try {
      final accepted = await widget.pairingClient.requestConnection(
        receiverAddress: InternetAddress(receiver.address),
        receiverPort: receiver.pairPort,
        fromName: defaultDeviceName(),
        streamUrl: 'http://${status!.ip}:${status.port}/stream',
      );
      if (!mounted) return;
      setState(() {
        _connectedTo = accepted ? receiver : null;
        _connectError = accepted
            ? null
            : 'Connexion refusée par ${receiver.name}.';
      });
    } catch (e) {
      if (mounted) setState(() => _connectError = 'Échec de connexion : $e');
    } finally {
      if (mounted) setState(() => _connectingTo = null);
    }
  }

  Future<void> _searchDlnaRenderers() async {
    setState(() {
      _dlnaSearching = true;
      _dlnaError = null;
    });
    try {
      final renderers = await widget.dlnaService.discover();
      if (!mounted) return;
      setState(() => _dlnaRenderers = renderers);
    } catch (e) {
      if (mounted) setState(() => _dlnaError = 'Recherche impossible : $e');
    } finally {
      if (mounted) setState(() => _dlnaSearching = false);
    }
  }

  Future<void> _castToDlna(DlnaRenderer renderer) async {
    final status = _status;
    if (status?.ip == null || status?.port == null) return;
    setState(() {
      _dlnaCasting = renderer;
      _dlnaError = null;
      _dlnaCastedTo = null;
    });
    try {
      await widget.dlnaService.cast(
        renderer,
        Uri.parse('http://${status!.ip}:${status.port}/stream'),
      );
      if (!mounted) return;
      setState(() => _dlnaCastedTo = renderer);
    } catch (e) {
      if (mounted) {
        setState(
          () => _dlnaError = '${renderer.name} n\'a pas accepté le flux : $e',
        );
      }
    } finally {
      if (mounted) setState(() => _dlnaCasting = null);
    }
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _scanner?.stop();
    if (_remoteControlEnabled) {
      // Ne laisse jamais le contrôle à distance actif après avoir quitté
      // cet écran : il doit être réautorisé consciemment à chaque fois.
      unawaited(widget.service.setRemoteControlEnabled(false));
    }
    super.dispose();
  }

  Future<void> _refreshRemoteControlStatus() async {
    try {
      final accessibilityEnabled = await widget.service
          .isAccessibilityServiceEnabled();
      final remoteControlEnabled = await widget.service
          .isRemoteControlEnabled();
      if (!mounted) return;
      setState(() {
        _accessibilityEnabled = accessibilityEnabled;
        _remoteControlEnabled = remoteControlEnabled;
      });
    } on MissingPluginException {
      // Ancienne version de l'app native sans ce canal : la section reste
      // simplement indisponible plutôt que de planter l'écran.
    }
  }

  Future<void> _openAccessibilitySettings() async {
    await widget.service.openAccessibilitySettings();
  }

  Future<void> _toggleRemoteControl(bool enabled) async {
    setState(() => _remoteControlBusy = true);
    try {
      final result = await widget.service.setRemoteControlEnabled(enabled);
      if (!mounted) return;
      setState(() => _remoteControlEnabled = result);
    } finally {
      if (mounted) setState(() => _remoteControlBusy = false);
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

  Future<void> _shareUrl() async {
    final url = _status?.url;
    if (url == null) return;
    // Passe par le menu de partage natif (Bluetooth, messagerie, e-mail...)
    // plutôt que de recopier l'adresse à la main.
    await SharePlus.instance.share(
      ShareParams(
        text: url,
        subject: 'Adresse de la projection SWVERTEX',
      ),
    );
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
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: QrImageView(
                        data: url,
                        size: 160,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Scanne ce code avec l\'appareil photo du récepteur pour '
                    'ouvrir l\'adresse directement, sans la taper.',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _copyUrl,
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Copier l\'adresse'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _shareUrl,
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text('Partager le lien'),
                      ),
                    ],
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
        _buildRemoteControlSection(context),
        const SizedBox(height: 20),
        _buildDirectConnectionSection(context),
        const SizedBox(height: 20),
        _buildDlnaSection(context),
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
              'Ouvre l\'adresse affichée dans un navigateur sur le récepteur '
              '(ou scanne le QR code / utilise « Partager le lien »).',
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
                  '• Pas de Miracast (bloqué par Android pour les apps '
                  'tierces) ; DLNA en prototype séparé ci-dessous, '
                  'compatibilité par téléviseur non garantie.',
                ),
                const Text(
                  '• La capture s\'arrête si Android révoque l\'autorisation.',
                ),
                const Text(
                  '• Connexion directe : Wi-Fi local uniquement (découverte '
                  'par diffusion UDP). Ni Bluetooth ni câble — chacun '
                  'nécessiterait un module natif par plateforme non '
                  'construit ici, voir docs/decisions-a-valider.md.',
                ),
                const Text(
                  '• Contrôle à distance : un seul tap à la fois (pas de '
                  'glissement/clavier), précision selon la découpe réelle de '
                  'l\'image, et expose le contrôle à quiconque atteint '
                  'l\'adresse tant qu\'il est activé.',
                ),
                const Text(
                  '• DLNA : envoie le flux MJPEG tel quel — la plupart des '
                  'téléviseurs DLNA attendent un format vidéo standard '
                  '(MP4/H.264), pas un flux multipart continu. Jamais '
                  'vérifié contre une vraie Smart TV dans cet environnement.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRemoteControlSection(BuildContext context) {
    final theme = Theme.of(context);
    final accessibilityEnabled = _accessibilityEnabled ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contrôle à distance (expérimental)',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Permet de cliquer sur l\'image dans le navigateur du récepteur '
              'pour reproduire un appui sur l\'écran du téléphone.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tant que c\'est activé, n\'importe qui atteignant '
                      'l\'adresse du flux sur le réseau local peut contrôler '
                      'cet écran. À n\'activer que sur un réseau de confiance, '
                      'et à désactiver juste après usage.',
                      style: TextStyle(
                        color: theme.colorScheme.onErrorContainer,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (!accessibilityEnabled) ...[
              Text(
                'Nécessite le service d\'accessibilité SWVERTEX, à activer '
                'manuellement dans les réglages Android.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: _openAccessibilitySettings,
                    child: const Text('Activer le service d\'accessibilité'),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _refreshRemoteControlStatus,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Vérifier à nouveau',
                  ),
                ],
              ),
            ] else
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _remoteControlEnabled
                          ? 'Contrôle à distance actif'
                          : 'Contrôle à distance désactivé',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  if (_remoteControlBusy)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Switch(
                      value: _remoteControlEnabled,
                      onChanged: _toggleRemoteControl,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectConnectionSection(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connexion directe (sans navigateur)',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Ouvre « Recevoir une projection » sur le PC/TV cible, puis '
              'connecte-toi ici une fois la capture démarrée.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            if (_receivers.isEmpty)
              const Text('Aucun récepteur détecté sur le réseau pour le moment.')
            else
              ..._receivers.map((receiver) {
                final isConnecting = _connectingTo == receiver;
                final isConnected = _connectedTo == receiver;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        isConnected ? Icons.cast_connected : Icons.tv,
                        color: isConnected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          receiver.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      FilledButton(
                        onPressed: (!_running || isConnecting)
                            ? null
                            : () => _connectTo(receiver),
                        child: isConnecting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(isConnected ? 'Connecté' : 'Se connecter'),
                      ),
                    ],
                  ),
                );
              }),
            if (!_running)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Démarre la capture pour pouvoir t\'y connecter directement.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            if (_connectError != null) ...[
              const SizedBox(height: 8),
              Text(
                _connectError!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDlnaSection(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Smart TV (DLNA, prototype)',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Aucune app à installer sur la TV si elle supporte déjà DLNA — '
              'mais rien ne garantit qu\'elle sache lire ce flux (voir les '
              'limites plus bas).',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _dlnaSearching ? null : _searchDlnaRenderers,
              icon: _dlnaSearching
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search, size: 18),
              label: Text(
                _dlnaSearching
                    ? 'Recherche en cours…'
                    : 'Rechercher des Smart TV',
              ),
            ),
            if (_dlnaRenderers.isNotEmpty) ...[
              const SizedBox(height: 12),
              ..._dlnaRenderers.map((renderer) {
                final isCasting = _dlnaCasting == renderer;
                final isCastedTo = _dlnaCastedTo == renderer;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        isCastedTo ? Icons.cast_connected : Icons.tv,
                        color: isCastedTo
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          renderer.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      FilledButton(
                        onPressed: (!_running || isCasting)
                            ? null
                            : () => _castToDlna(renderer),
                        child: isCasting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(isCastedTo ? 'Envoyé' : 'Caster'),
                      ),
                    ],
                  ),
                );
              }),
            ],
            if (_dlnaError != null) ...[
              const SizedBox(height: 8),
              Text(
                _dlnaError!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Contrairement à la connexion directe, la TV ne demande pas '
              'confirmation : elle essaie simplement de lire l\'adresse '
              'envoyée.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
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
