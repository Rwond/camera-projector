import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:swvertex_camera_projector/features/photos/photo_viewer_screen.dart';

// PNG 1x1 valide (transparent) : les octets doivent être décodables par
// Image.memory, un tableau arbitraire ferait planter le décodeur.
const _onePixelPng = [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
];

Future<Uint8List?> _fakePicker() async => Uint8List.fromList(_onePixelPng);
Future<Uint8List?> _cancelledPicker() async => null;

void main() {
  testWidgets('aucune photo choisie : le plein écran est désactivé', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: PhotoViewerScreen(pickImage: _cancelledPicker)),
    );

    expect(find.text('Aucune photo choisie'), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('choisir une photo affiche son aperçu et active le plein écran', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: PhotoViewerScreen(pickImage: _fakePicker)),
    );

    await tester.tap(find.text('Choisir une photo'));
    await tester.pumpAndSettle();

    expect(find.text('Aucune photo choisie'), findsNothing);
    expect(find.byType(Image), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNotNull);
  });

  testWidgets('le plein écran affiche l\'image et se ferme au toucher', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: PhotoViewerScreen(pickImage: _fakePicker)),
    );

    await tester.tap(find.text('Choisir une photo'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Afficher en plein écran'));
    await tester.pumpAndSettle();

    expect(find.text('Touchez l\'écran pour quitter'), findsOneWidget);

    await tester.tap(find.text('Touchez l\'écran pour quitter'));
    await tester.pumpAndSettle();

    expect(find.text('Touchez l\'écran pour quitter'), findsNothing);
  });
}
