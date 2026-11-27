import 'package:flutter/material.dart';

class _Stroke {
  _Stroke({required this.color, required this.width});

  final Color color;
  final double width;
  final List<Offset> points = [];
}

/// Source « Tableau blanc » : surface de dessin libre (trait, couleur,
/// épaisseur), avec annuler/tout effacer. Ne diffuse rien par elle-même — à
/// combiner avec le Mode B (capture d'écran) ou Smart TV (DLNA) déjà réels
/// pour projeter ce qui est dessiné ici sur un autre appareil. Le dessin
/// n'est **pas** enregistré : il est perdu en quittant cet écran.
class WhiteboardScreen extends StatefulWidget {
  const WhiteboardScreen({super.key});

  @override
  State<WhiteboardScreen> createState() => _WhiteboardScreenState();
}

class _WhiteboardScreenState extends State<WhiteboardScreen> {
  static const _colors = [
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
  ];
  static const _widths = [2.0, 4.0, 8.0];

  final List<_Stroke> _strokes = [];
  Color _color = _colors.first;
  double _strokeWidth = _widths[1];

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _strokes.add(_Stroke(color: _color, width: _strokeWidth)..points.add(details.localPosition));
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() => _strokes.last.points.add(details.localPosition));
  }

  void _undo() {
    if (_strokes.isEmpty) return;
    setState(() => _strokes.removeLast());
  }

  Future<void> _clear() async {
    if (_strokes.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Effacer le tableau ?'),
        content: const Text('Le dessin actuel sera définitivement perdu.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Effacer')),
        ],
      ),
    );
    if (confirmed == true && mounted) setState(() => _strokes.clear());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasStrokes = _strokes.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau blanc'),
        actions: [
          IconButton(
            onPressed: hasStrokes ? _undo : null,
            icon: const Icon(Icons.undo),
            tooltip: 'Annuler le dernier trait',
          ),
          IconButton(
            onPressed: hasStrokes ? _clear : null,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Tout effacer',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ColoredBox(
              color: Colors.white,
              child: GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                child: CustomPaint(
                  painter: _WhiteboardPainter(_strokes),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
          _buildToolbar(theme),
        ],
      ),
    );
  }

  Widget _buildToolbar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (final c in _colors)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _ColorSwatch(
                    color: c,
                    selected: _color == c,
                    onTap: () => setState(() => _color = c),
                  ),
                ),
              const Spacer(),
              for (final w in _widths)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: ChoiceChip(
                    label: Text('${w.toInt()}'),
                    selected: _strokeWidth == w,
                    onSelected: (_) => setState(() => _strokeWidth = w),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Dessin non enregistré : perdu en quittant cet écran. Ne diffuse '
            'rien par lui-même — combine avec le Mode B (capture d\'écran) ou '
            'Smart TV (DLNA) depuis l\'onglet Sources pour projeter ce tableau '
            'ailleurs.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({required this.color, required this.selected, required this.onTap});

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? theme.colorScheme.primary : Colors.transparent,
            width: 3,
          ),
        ),
      ),
    );
  }
}

class _WhiteboardPainter extends CustomPainter {
  _WhiteboardPainter(this.strokes);

  final List<_Stroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      final linePaint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      for (var i = 0; i < stroke.points.length - 1; i++) {
        canvas.drawLine(stroke.points[i], stroke.points[i + 1], linePaint);
      }
      if (stroke.points.length == 1) {
        // Un simple tap sans glissement : dessine tout de même un point.
        final dotPaint = Paint()
          ..color = stroke.color
          ..style = PaintingStyle.fill;
        canvas.drawCircle(stroke.points.first, stroke.width / 2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WhiteboardPainter oldDelegate) => true;
}
