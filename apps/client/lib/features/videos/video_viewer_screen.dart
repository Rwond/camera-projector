import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class PickedVideo {
  const PickedVideo({required this.name, required this.path});

  final String name;

  /// Chemin de fichier local. `null` sur le Web : `video_player` y a besoin
  /// d'une URL (réseau ou blob), pas d'un chemin de fichier — non construit
  /// ici (voir le message honnête affiché à la place).
  final String? path;
}

Future<PickedVideo?> _pickVideoFromDisk() async {
  final file = await FilePicker.pickFile(type: FileType.video);
  if (file == null) return null;
  return PickedVideo(name: file.name, path: file.path);
}

/// Source « Vidéos » : choisit une vidéo du téléphone/PC et la lit en plein
/// écran. Ne diffuse rien par elle-même — à combiner avec le Mode B (capture
/// d'écran) ou Smart TV (DLNA) déjà réels pour projeter ce qui est affiché ici
/// sur un autre appareil.
class VideoViewerScreen extends StatefulWidget {
  const VideoViewerScreen({
    super.key,
    this.pickVideo = _pickVideoFromDisk,
    this.controllerFactory = VideoPlayerController.file,
  });

  final Future<PickedVideo?> Function() pickVideo;

  /// Injectable pour les tests : construit le contrôleur à partir du fichier
  /// choisi. Par défaut, le vrai `VideoPlayerController.file`.
  final VideoPlayerController Function(File) controllerFactory;

  @override
  State<VideoViewerScreen> createState() => _VideoViewerScreenState();
}

class _VideoViewerScreenState extends State<VideoViewerScreen> {
  PickedVideo? _picked;
  VideoPlayerController? _controller;
  bool _initializing = false;
  String? _initError;

  bool get _ready => _controller?.value.isInitialized ?? false;

  Future<void> _chooseVideo() async {
    final picked = await widget.pickVideo();
    if (picked == null || !mounted) return;

    await _controller?.dispose();
    setState(() {
      _picked = picked;
      _controller = null;
      _initError = null;
    });

    if (kIsWeb || picked.path == null) {
      // Pas de chemin de fichier exploitable sur le Web avec cette
      // implémentation — message honnête affiché par build(), aucune
      // tentative de lecture.
      return;
    }

    setState(() => _initializing = true);
    try {
      final controller = widget.controllerFactory(File(picked.path!));
      // Les échecs de canal de plateforme n'étant pas toujours signalés par
      // une exception claire selon la plateforme, un délai évite un spinner
      // infini plutôt qu'un message honnête.
      await controller.initialize().timeout(const Duration(seconds: 8));
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (e) {
      // Pas de controller.dispose() ici : quand l'initialisation échoue
      // avant d'avoir créé quoi que ce soit côté plateforme, dispose() attend
      // indéfiniment cette création qui n'arrivera jamais — observé dans cet
      // environnement de test, qui n'implémente pas le canal vidéo. Rien n'a
      // été créé côté natif à libérer dans ce cas.
      if (mounted) setState(() => _initError = '$e');
    } finally {
      if (mounted) setState(() => _initializing = false);
    }
  }

  Future<void> _showFullScreen() async {
    final controller = _controller;
    if (controller == null || !_ready) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => _FullScreenVideo(controller: controller)),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Widget _buildPreview(ThemeData theme) {
    final picked = _picked;
    if (picked == null) {
      return Container(
        height: 140,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('Aucune vidéo choisie'),
      );
    }
    if (kIsWeb || picked.path == null) {
      return Text(
        '« ${picked.name} » choisie, mais la lecture vidéo n\'est pas prise en '
        'charge depuis le navigateur dans ce prototype (aucun chemin de '
        'fichier exploitable sur le Web).',
        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
      );
    }
    if (_initializing) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_initError != null) {
      return Text(
        'Aperçu vidéo indisponible : $_initError',
        style: TextStyle(color: theme.colorScheme.error),
      );
    }
    final controller = _controller;
    if (controller != null && _ready) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(controller),
              IconButton(
                iconSize: 48,
                color: Colors.white,
                icon: Icon(controller.value.isPlaying ? Icons.pause_circle : Icons.play_circle),
                onPressed: () => setState(
                  () => controller.value.isPlaying ? controller.pause() : controller.play(),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return const Text('Aucune vidéo choisie');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Vidéos')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Vidéo à lire', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _buildPreview(theme),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _chooseVideo,
                    icon: const Icon(Icons.video_file_outlined),
                    label: const Text('Choisir une vidéo'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _ready ? _showFullScreen : null,
            icon: const Icon(Icons.fullscreen),
            label: const Text('Lire en plein écran'),
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
                    '• Lit uniquement, en plein écran — il ne diffuse rien par '
                    'lui-même vers un autre appareil.',
                  ),
                  const Text(
                    '• Non disponible sur le Web dans ce prototype : la lecture '
                    'depuis un fichier choisi dans le navigateur demanderait une '
                    'URL blob dédiée, non construite ici.',
                  ),
                  const Text(
                    '• Pour projeter cette vidéo ailleurs : démarre le Mode B '
                    '(capture d\'écran) ou Smart TV (DLNA) depuis l\'onglet '
                    'Sources pendant que cet écran est affiché.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FullScreenVideo extends StatefulWidget {
  const _FullScreenVideo({required this.controller});

  final VideoPlayerController controller;

  @override
  State<_FullScreenVideo> createState() => _FullScreenVideoState();
}

class _FullScreenVideoState extends State<_FullScreenVideo> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTick);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTick);
    super.dispose();
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(
          () => controller.value.isPlaying ? controller.pause() : controller.play(),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Quitter le plein écran',
              ),
            ),
            if (!controller.value.isPlaying)
              const Center(
                child: Icon(Icons.play_circle, color: Colors.white70, size: 64),
              ),
          ],
        ),
      ),
    );
  }
}
