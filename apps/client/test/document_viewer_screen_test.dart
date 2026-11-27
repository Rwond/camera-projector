import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:swvertex_camera_projector/features/documents/document_viewer_screen.dart';

Future<PickedDocument?> _fakeTextPicker() async =>
    PickedDocument(name: 'notes.txt', bytes: Uint8List.fromList(utf8.encode('Bonjour le monde')));

Future<PickedDocument?> _fakePdfPicker() async =>
    PickedDocument(name: 'rapport.pdf', bytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46]));

Future<PickedDocument?> _cancelledPicker() async => null;

void main() {
  testWidgets('aucun document choisi : le plein écran est désactivé', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: DocumentViewerScreen(pickDocument: _cancelledPicker)),
    );

    expect(find.text('Aucun document choisi'), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('un fichier texte est affiché et peut passer en plein écran', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: DocumentViewerScreen(pickDocument: _fakeTextPicker)),
    );

    await tester.tap(find.text('Choisir un document'));
    await tester.pumpAndSettle();

    expect(find.text('Bonjour le monde'), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNotNull);

    await tester.tap(find.text('Afficher en plein écran'));
    await tester.pumpAndSettle();

    expect(find.text('Touchez l\'écran pour quitter'), findsOneWidget);
    await tester.tap(find.text('Touchez l\'écran pour quitter'));
    await tester.pumpAndSettle();
    expect(find.text('Touchez l\'écran pour quitter'), findsNothing);
  });

  testWidgets('un format non pris en charge affiche un message honnête, pas un faux rendu', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: DocumentViewerScreen(pickDocument: _fakePdfPicker)),
    );

    await tester.tap(find.text('Choisir un document'));
    await tester.pumpAndSettle();

    expect(find.textContaining('aperçu non disponible'), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });
}
