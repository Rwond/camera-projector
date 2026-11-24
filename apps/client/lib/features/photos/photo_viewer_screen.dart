import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

Future<Uint8List?> _pickImageFromDisk() async {
  final file = await FilePicker.pickFile(type: FileType.image);
  return file?.readAsBytes();
}

/// Source « Photos » : choisit une photo du téléphone et l'affiche en plein
/// écran. Ne diffuse rien par elle-même — à combiner avec le Mode B (capture
/// d'écran) ou Smart TV (DLNA) déjà réels pour projeter ce qui est affiché
/// ici sur un autre appareil, exactement comme n'importe quel autre contenu
/// à l'écran du téléphone.
class PhotoViewerScreen extends StatefulWidget {
  const PhotoViewerScreen({super.key, this.pickImage = _pickImageFromDisk});

  final Future<Uint8List?> Function() pickImage;

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  Uint8List? _imageBytes;

  Future<void> _choosePicture() async {
    final bytes = await widget.pickImage();
    if (bytes == null || !mounted) return;
    setState(() => _imageBytes = bytes);
  }

  Future<void> _showFullScreen() async {
    final bytes = _imageBytes;
    if (bytes == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => _FullScreenPhoto(imageBytes: bytes)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Photos')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Photo à afficher', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  if (_imageBytes != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(_imageBytes!, height: 180, fit: BoxFit.contain),
                    )
                  else
                    Container(
                      height: 140,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Aucune photo choisie'),
                    ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _choosePicture,
                    icon: const Icon(Icons.photo_outlined),
                    label: const Text('Choisir une photo'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _imageBytes == null ? null : _showFullScreen,
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
                    '• Affiche uniquement, en plein écran — il ne diffuse rien '
                    'par lui-même vers un autre appareil.',
                  ),
                  const Text(
                    '• Pour projeter cette photo ailleurs : démarre le Mode B '
                    '(capture d\'écran) ou Smart TV (DLNA) depuis l\'onglet '
                    'Sources pendant que cet écran est affiché — exactement '
                    'comme pour n\'importe quel contenu à l\'écran.',
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

class _FullScreenPhoto extends StatelessWidget {
  const _FullScreenPhoto({required this.imageBytes});

  final Uint8List imageBytes;

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
            Center(child: Image.memory(imageBytes, fit: BoxFit.contain)),
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
