import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/mjpeg_client.dart';

/// Affiche un flux MJPEG reçu directement dans l'application — c'est l'écran
/// qui apparaît côté récepteur une fois une demande de connexion acceptée,
/// sans passer par un navigateur.
class MjpegViewerScreen extends StatefulWidget {
  const MjpegViewerScreen({
    super.key,
    required this.streamUri,
    required this.sourceName,
    this.framesOf = _defaultFrames,
  });

  final Uri streamUri;
  final String sourceName;
  final Stream<Uint8List> Function(Uri uri) framesOf;

  static Stream<Uint8List> _defaultFrames(Uri uri) =>
      const MjpegClient().frames(uri);

  @override
  State<MjpegViewerScreen> createState() => _MjpegViewerScreenState();
}

class _MjpegViewerScreenState extends State<MjpegViewerScreen> {
  late final Stream<Uint8List> _frames = widget.framesOf(widget.streamUri);
  Uint8List? _lastFrame;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            StreamBuilder<Uint8List>(
              stream: _frames,
              builder: (context, snapshot) {
                if (snapshot.hasError && _error == null) {
                  _error = 'Flux interrompu : ${snapshot.error}';
                }
                if (snapshot.hasData) {
                  _lastFrame = snapshot.data;
                  _error = null;
                }
                final frame = _lastFrame;
                if (frame == null) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Connexion à ${widget.sourceName}…',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  );
                }
                return Center(
                  child: Image.memory(frame, gaplessPlayback: true),
                );
              },
            ),
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Projection depuis ${widget.sourceName}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    tooltip: 'Fermer',
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
            if (_error != null)
              Positioned(
                bottom: 24,
                left: 24,
                right: 24,
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
