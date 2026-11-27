import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

CameraController _defaultControllerFactory(CameraDescription description) {
  return CameraController(description, ResolutionPreset.medium, enableAudio: false);
}

String _friendlyError(Object error) {
  if (error is CameraException) {
    final code = error.code.toLowerCase();
    if (code.contains('denied') || code.contains('permission')) {
      return 'Accès à la caméra refusé. Autorise l\'accès dans les réglages de '
          'l\'appareil ou du navigateur, puis réessaie.';
    }
    return 'Impossible d\'ouvrir la caméra : ${error.description ?? error.code}';
  }
  if (error.toString().contains('MissingPluginException') ||
      error.toString().contains('UnimplementedError')) {
    return 'Caméra non disponible sur cette plateforme dans ce prototype '
        '(aucun pilote caméra installé pour ce client).';
  }
  return 'Impossible d\'ouvrir la caméra : $error';
}

/// Source « Caméra » : affiche le flux de la caméra de l'appareil en direct,
/// en plein écran optionnel. Ne l'enregistre pas et ne le diffuse pas par
/// elle-même — à combiner avec le Mode B (capture d'écran) ou Smart TV (DLNA)
/// déjà réels pour projeter ce flux sur un autre appareil.
class CameraScreen extends StatefulWidget {
  const CameraScreen({
    super.key,
    this.listCameras = availableCameras,
    this.controllerFactory = _defaultControllerFactory,
  });

  final Future<List<CameraDescription>> Function() listCameras;
  final CameraController Function(CameraDescription) controllerFactory;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool _loading = false;
  String? _error;
  List<CameraDescription> _cameras = const [];
  int _selectedIndex = 0;
  CameraController? _controller;

  bool get _ready => _controller?.value.isInitialized ?? false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cameras = await widget.listCameras();
      if (cameras.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'Aucune caméra détectée sur cet appareil.';
        });
        return;
      }
      await _openCamera(cameras, 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _friendlyError(e);
      });
    }
  }

  Future<void> _openCamera(List<CameraDescription> cameras, int index) async {
    final controller = widget.controllerFactory(cameras[index]);
    try {
      await controller.initialize();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _cameras = cameras;
        _error = _friendlyError(e);
      });
      return;
    }
    if (!mounted) {
      await controller.dispose();
      return;
    }
    final previous = _controller;
    setState(() {
      _loading = false;
      _cameras = cameras;
      _selectedIndex = index;
      _controller = controller;
    });
    await previous?.dispose();
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    final nextIndex = (_selectedIndex + 1) % _cameras.length;
    setState(() => _loading = true);
    await _openCamera(_cameras, nextIndex);
  }

  Future<void> _showFullScreen() async {
    final controller = _controller;
    if (controller == null || !_ready) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => _FullScreenCamera(controller: controller)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Caméra')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Caméra en direct', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _buildPreviewArea(theme),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _loading ? null : _start,
                        icon: const Icon(Icons.videocam_outlined),
                        label: Text(_ready ? 'Redémarrer la caméra' : 'Démarrer la caméra'),
                      ),
                      IconButton(
                        onPressed: (_cameras.length > 1 && !_loading) ? _switchCamera : null,
                        icon: const Icon(Icons.cameraswitch_outlined),
                        tooltip: 'Changer de caméra',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _ready ? _showFullScreen : null,
            icon: const Icon(Icons.fullscreen),
            label: const Text('Afficher en plein écran'),
          ),
          const SizedBox(height: 20),
          Card(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ce que fait cet écran', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  const Text(
                    '• Affiche le flux caméra en direct, en plein écran optionnel — il '
                    'ne l\'enregistre pas et ne le diffuse pas par lui-même vers un '
                    'autre appareil.',
                  ),
                  const Text(
                    '• Pour projeter ce flux ailleurs : démarre le Mode B (capture '
                    'd\'écran) ou Smart TV (DLNA) depuis l\'onglet Sources pendant que '
                    'cet écran est affiché — exactement comme pour n\'importe quel '
                    'contenu à l\'écran.',
                  ),
                  const Text(
                    '• Non disponible sur Windows dans ce prototype : aucun pilote '
                    'caméra n\'y est installé pour ce client. Fonctionne sur Android, '
                    'iOS et dans un navigateur web qui autorise l\'accès à la caméra.',
                  ),
                  const Text(
                    '• Jamais vérifié avec une vraie caméra physique dans cet '
                    'environnement de développement : seul le chemin d\'erreur honnête '
                    '(caméra absente ou plateforme non prise en charge) a pu être '
                    'vérifié ici.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewArea(ThemeData theme) {
    if (_ready) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 220,
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller!.value.previewSize?.height ?? 220,
              height: _controller!.value.previewSize?.width ?? 220,
              child: CameraPreview(_controller!),
            ),
          ),
        ),
      );
    }
    if (_loading) {
      return Container(
        height: 140,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const CircularProgressIndicator(),
      );
    }
    if (_error != null) {
      return Container(
        height: 140,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          _error!,
          textAlign: TextAlign.center,
          style: TextStyle(color: theme.colorScheme.onErrorContainer),
        ),
      );
    }
    return Container(
      height: 140,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text('Caméra non démarrée'),
    );
  }
}

class _FullScreenCamera extends StatelessWidget {
  const _FullScreenCamera({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        behavior: HitTestBehavior.opaque,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(child: CameraPreview(controller)),
            const Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Text(
                'Touchez l\'écran pour quitter',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
