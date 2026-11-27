import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:swvertex_camera_projector/features/whiteboard/whiteboard_screen.dart';

void main() {
  testWidgets('tableau vide : annuler et tout effacer sont désactivés', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: WhiteboardScreen()));

    final undo = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.undo));
    final clear = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.delete_outline));
    expect(undo.onPressed, isNull);
    expect(clear.onPressed, isNull);
  });

  testWidgets('dessiner un trait active annuler, qui le retire', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: WhiteboardScreen()));

    await tester.dragFrom(const Offset(100, 100), const Offset(60, 40));
    await tester.pumpAndSettle();

    var undo = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.undo));
    expect(undo.onPressed, isNotNull);

    await tester.tap(find.byTooltip('Annuler le dernier trait'));
    await tester.pumpAndSettle();

    undo = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.undo));
    expect(undo.onPressed, isNull);
  });

  testWidgets('tout effacer demande confirmation avant de vider le tableau', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: WhiteboardScreen()));

    await tester.dragFrom(const Offset(100, 100), const Offset(60, 40));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Tout effacer'));
    await tester.pumpAndSettle();

    expect(find.text('Effacer le tableau ?'), findsOneWidget);

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    var undo = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.undo));
    expect(undo.onPressed, isNotNull, reason: 'annuler la confirmation garde le dessin');

    await tester.tap(find.byTooltip('Tout effacer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Effacer'));
    await tester.pumpAndSettle();

    undo = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.undo));
    expect(undo.onPressed, isNull);
  });

  testWidgets('choisir une couleur et une épaisseur ne plante pas', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: WhiteboardScreen()));

    await tester.tap(find.byType(ChoiceChip).first);
    await tester.pumpAndSettle();

    await tester.dragFrom(const Offset(100, 100), const Offset(60, 40));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
