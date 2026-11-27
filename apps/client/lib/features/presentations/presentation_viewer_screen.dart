import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

Future<List<Uint8List>> _pickSlidesFromDisk() async {
  final files = await FilePicker.pickFiles(type: FileType.image);
  final slides = <Uint8List>[];
  for (final file in files) {
    slides.add(await file.readAsBytes());
  }
  return slides;
}

/// Source « Présentations » : choisit une série d'images et les affiche comme
/// un diaporama plein écran, navigable diapositive par diapositive. Ne lit
/// pas les fichiers .pptx/.key/.odp eux-mêmes — construire un moteur de rendu
/// de présentation est un chantier à part entière, non entamé ici (voir
/// l'encart « Ce que fait cet écran »). Ne diffuse rien par elle-même — à
/// combiner avec le Mode B (capture d'écran) ou Smart TV (DLNA) déjà réels
/// pour projeter ce qui est affiché ici sur un autre appareil.
class PresentationViewerScreen extends StatefulWidget {
  const PresentationViewerScreen({super.key, this.pickSlides = _pickSlidesFromDisk});

  final Future<List<Uint8List>> Function() pickSlides;

  @override
  State<PresentationViewerScreen> createState() => _PresentationViewerScreenState();
}

class _PresentationViewerScreenState extends State<PresentationViewerScreen> {
  List<Uint8List> _slides = const [];
  int _index = 0;

  Future<void> _choose() async {
    final slides = await widget.pickSlides();
    if (slides.isEmpty || !mounted) return;
    setState(() {
      _slides = slides;
      _index = 0;
    });
  }

  void _previous() {
    if (_index > 0) setState(() => _index--);
  }

  void _next() {
    if (_index < _slides.length - 1) setState(() => _index++);
  }

  Future<void> _startSlideshow() async {
    if (_slides.isEmpty) return;
    final result = await Navigator.of(context).push<int>(
      MaterialPageRoute<int>(
        builder: (_) => _FullScreenSlideshow(slides: _slides, initialIndex: _index),
      ),
    );
    if (result != null && mounted) setState(() => _index = result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSlides = _slides.isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text('Présentations')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Diaporama', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  if (!hasSlides)
                    Container(
                      height: 140,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Aucune image choisie'),
                    )
                  else ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(_slides[_index], height: 180, fit: BoxFit.contain),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: _index > 0 ? _previous : null,
                          icon: const Icon(Icons.chevron_left),
                          tooltip: 'Diapositive précédente',
                        ),
                        Text('${_index + 1} / ${_slides.length}'),
                        IconButton(
                          onPressed: _index < _slides.length - 1 ? _next : null,
                          icon: const Icon(Icons.chevron_right),
                          tooltip: 'Diapositive suivante',
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _choose,
                    icon: const Icon(Icons.slideshow_outlined),
                    label: Text(hasSlides ? 'Choisir d\'autres images' : 'Choisir des images'),
                  ),
                  if (hasSlides)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Choisir à nouveau remplace entièrement le diaporama actuel.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: hasSlides ? _startSlideshow : null,
            icon: const Icon(Icons.fullscreen),
            label: const Text('Démarrer le diaporama'),
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
                    '• Affiche une série d\'images choisies comme un diaporama '
                    'plein écran, navigable diapositive par diapositive — il ne '
                    'diffuse rien par lui-même vers un autre appareil.',
                  ),
                  const Text(
                    '• Ne lit pas les fichiers .pptx/.key/.odp eux-mêmes : aucun '
                    'moteur de rendu de présentation n\'est construit ici. Pour '
                    'utiliser une présentation existante, exporte-la en images '
                    '(une par diapositive) depuis l\'application d\'origine, '
                    'puis choisis ces images ici.',
                  ),
                  const Text(
                    '• Pour projeter ce diaporama ailleurs : démarre le Mode B '
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

class _FullScreenSlideshow extends StatefulWidget {
  const _FullScreenSlideshow({required this.slides, required this.initialIndex});

  final List<Uint8List> slides;
  final int initialIndex;

  @override
  State<_FullScreenSlideshow> createState() => _FullScreenSlideshowState();
}

class _FullScreenSlideshowState extends State<_FullScreenSlideshow> {
  late int _index = widget.initialIndex;

  void _previous() {
    if (_index > 0) setState(() => _index--);
  }

  void _next() {
    if (_index < widget.slides.length - 1) setState(() => _index++);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.of(context).pop(_index);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: Image.memory(widget.slides[_index], fit: BoxFit.contain),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(_index),
                  tooltip: 'Quitter le diaporama',
                ),
              ),
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Text(
                      '${_index + 1} / ${widget.slides.length}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          iconSize: 36,
                          color: Colors.white,
                          onPressed: _index > 0 ? _previous : null,
                          icon: const Icon(Icons.chevron_left),
                          tooltip: 'Diapositive précédente',
                        ),
                        const SizedBox(width: 40),
                        IconButton(
                          iconSize: 36,
                          color: Colors.white,
                          onPressed: _index < widget.slides.length - 1 ? _next : null,
                          icon: const Icon(Icons.chevron_right),
                          tooltip: 'Diapositive suivante',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
