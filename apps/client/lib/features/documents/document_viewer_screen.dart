import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class PickedDocument {
  const PickedDocument({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

/// Extensions de texte brut que ce prototype sait réellement afficher. Toute
/// autre extension (pdf, docx, pptx...) affiche un message honnête plutôt que
/// de prétendre les rendre — construire un moteur de rendu par format est un
/// chantier à part entière, non entamé ici.
const supportedTextExtensions = {'txt', 'md', 'csv', 'log', 'json'};

String _extensionOf(String name) {
  final dot = name.lastIndexOf('.');
  if (dot == -1 || dot == name.length - 1) return '';
  return name.substring(dot + 1).toLowerCase();
}

bool isSupportedTextDocument(String name) =>
    supportedTextExtensions.contains(_extensionOf(name));

Future<PickedDocument?> _pickDocumentFromDisk() async {
  final file = await FilePicker.pickFile(type: FileType.any);
  if (file == null) return null;
  return PickedDocument(name: file.name, bytes: await file.readAsBytes());
}

/// Source « Documents » : choisit un fichier et l'affiche en plein écran s'il
/// s'agit de texte brut. Ne diffuse rien par elle-même — à combiner avec le
/// Mode B (capture d'écran) ou Smart TV (DLNA) déjà réels pour projeter ce qui
/// est affiché ici sur un autre appareil.
class DocumentViewerScreen extends StatefulWidget {
  const DocumentViewerScreen({super.key, this.pickDocument = _pickDocumentFromDisk});

  final Future<PickedDocument?> Function() pickDocument;

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  PickedDocument? _document;
  String? _text;
  String? _decodeError;

  Future<void> _chooseDocument() async {
    final document = await widget.pickDocument();
    if (document == null || !mounted) return;
    setState(() {
      _document = document;
      _text = null;
      _decodeError = null;
    });
    if (isSupportedTextDocument(document.name)) {
      try {
        final text = utf8.decode(document.bytes, allowMalformed: true);
        if (mounted) setState(() => _text = text);
      } catch (e) {
        if (mounted) setState(() => _decodeError = 'Lecture impossible : $e');
      }
    }
  }

  Future<void> _showFullScreen() async {
    final text = _text;
    final document = _document;
    if (text == null || document == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _FullScreenDocument(name: document.name, text: text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final document = _document;
    return Scaffold(
      appBar: AppBar(title: const Text('Documents')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Document à afficher', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  if (document == null)
                    Container(
                      height: 100,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Aucun document choisi'),
                    )
                  else if (_decodeError != null)
                    Text(_decodeError!, style: TextStyle(color: theme.colorScheme.error))
                  else if (_text != null)
                    Container(
                      height: 160,
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          _text!,
                          style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                        ),
                      ),
                    )
                  else
                    Text(
                      '« ${document.name} » : aperçu non disponible pour ce type de '
                      'fichier dans ce prototype — seuls les fichiers texte brut '
                      '(${supportedTextExtensions.map((e) => '.$e').join(', ')}) sont '
                      'affichés.',
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _chooseDocument,
                    icon: const Icon(Icons.description_outlined),
                    label: const Text('Choisir un document'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _text == null ? null : _showFullScreen,
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
                    '• Affiche uniquement du texte brut, en plein écran — il ne '
                    'diffuse rien par lui-même vers un autre appareil.',
                  ),
                  Text(
                    '• Seules les extensions ${supportedTextExtensions.map((e) => '.$e').join(', ')} '
                    'sont rendues. PDF, Word, PowerPoint et autres formats binaires ne '
                    'sont pas pris en charge ici — un moteur de rendu par format est un '
                    'chantier à part entière, non entamé.',
                  ),
                  const Text(
                    '• Pour projeter ce document ailleurs : démarre le Mode B '
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

class _FullScreenDocument extends StatelessWidget {
  const _FullScreenDocument({required this.name, required this.text});

  final String name;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 16,
                  ),
                ),
              ),
              const Positioned(
                bottom: 8,
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
      ),
    );
  }
}
