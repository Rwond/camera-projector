import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'lens_brightness_service.dart';
import 'lens_flip_mode.dart';

Future<Uint8List?> _pickImageFromDisk() async {
  final file = await FilePicker.pickFile(type: FileType.image);
  return file?.readAsBytes();
}

/// Écran de réglage du mode C (lentille optique) : affiche une image ou un
/// motif de calibrage en plein écran, orienté selon le montage optique de
/// l'accessoire. L'accessoire lui-même (lentille, boîtier) n'est ni fourni
/// ni spécifié par ce projet — voir docs/decisions-a-valider.md.
class LensProjectionScreen extends StatefulWidget {
  const LensProjectionScreen({
    super.key,
    this.brightness = const LensBrightnessService(),
    this.pickImage = _pickImageFromDisk,
  });

  final LensBrightnessService brightness;
  final Future<Uint8List?> Function() pickImage;

  @override
  State<LensProjectionScreen> createState() => _LensProjectionScreenState();
}

class _LensProjectionScreenState extends State<LensProjectionScreen> {
  Uint8List? _imageBytes;
  LensFlipMode _flipMode = LensFlipMode.both;

  Future<void> _choosePicture() async {
    final bytes = await widget.pickImage();
    if (bytes == null || !mounted) return;
    setState(() => _imageBytes = bytes);
  }

  Future<void> _startProjection() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _LensDisplayScreen(
          imageBytes: _imageBytes,
          flipMode: _flipMode,
          brightness: widget.brightness,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Projection par lentille (prototype)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Image à projeter', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  if (_imageBytes != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        _imageBytes!,
                        height: 140,
                        fit: BoxFit.contain,
                      ),
                    )
                  else
                    Container(
                      height: 100,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Aucune image : motif de calibrage'),
                    ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _choosePicture,
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('Choisir une image'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Orientation optique', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Selon le montage de la lentille, l\'image projetée peut être inversée.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: LensFlipMode.values.map((mode) {
                      return ChoiceChip(
                        label: Text(mode.label),
                        selected: _flipMode == mode,
                        onSelected: (_) => setState(() => _flipMode = mode),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _startProjection,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Démarrer la projection'),
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
                  const Text(
                    '• Nécessite un accessoire optique (lentille) non fourni par '
                    'l\'application : mise au point et distance restent manuelles.',
                  ),
                  const Text(
                    '• La luminosité maximale automatique n\'est pas disponible '
                    'sur toutes les plateformes (ex. web).',
                  ),
                  const Text(
                    '• Le montage optique définitif reste à choisir '
                    '(docs/decisions-a-valider.md) : les 4 orientations ci-dessus '
                    'couvrent les cas courants en attendant.',
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

class _LensDisplayScreen extends StatefulWidget {
  const _LensDisplayScreen({
    required this.imageBytes,
    required this.flipMode,
    required this.brightness,
  });

  final Uint8List? imageBytes;
  final LensFlipMode flipMode;
  final LensBrightnessService brightness;

  @override
  State<_LensDisplayScreen> createState() => _LensDisplayScreenState();
}

class _LensDisplayScreenState extends State<_LensDisplayScreen> {
  @override
  void initState() {
    super.initState();
    widget.brightness.maximize();
  }

  @override
  void dispose() {
    widget.brightness.restore();
    super.dispose();
  }

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
            Center(
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..scaleByDouble(
                    widget.flipMode.scaleX,
                    widget.flipMode.scaleY,
                    1.0,
                    1.0,
                  ),
                child: widget.imageBytes != null
                    ? Image.memory(widget.imageBytes!, fit: BoxFit.contain)
                    : const _CalibrationPattern(),
              ),
            ),
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

class _CalibrationPattern extends StatelessWidget {
  const _CalibrationPattern();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: CustomPaint(painter: _CalibrationPainter()),
    );
  }
}

class _CalibrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = Colors.white;
    canvas.drawRect(Offset.zero & size, background);

    final line = Paint()
      ..color = Colors.black
      ..strokeWidth = 2;
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), line);
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), line);

    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    for (var i = 1; i <= 3; i++) {
      canvas.drawCircle(center, radius * i / 3, line);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
