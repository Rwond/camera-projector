import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:swvertex_camera_projector/features/presentations/presentation_viewer_screen.dart';

const _onePixelPng = [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
];

Future<List<Uint8List>> _cancelledPicker() async => [];

Future<List<Uint8List>> _threeSlidesPicker() async =>
    List.generate(3, (_) => Uint8List.fromList(_onePixelPng));

void main() {
  testWidgets('aucune image choisie : le diaporama est désactivé', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: PresentationViewerScreen(pickSlides: _cancelledPicker)),
    );

    expect(find.text('Aucune image choisie'), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('choisir des images affiche le compteur et permet de naviguer', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: PresentationViewerScreen(pickSlides: _threeSlidesPicker)),
    );

    await tester.tap(find.text('Choisir des images'));
    await tester.pumpAndSettle();

    expect(find.text('1 / 3'), findsOneWidget);
    final filled = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(filled.onPressed, isNotNull);

    await tester.tap(find.byTooltip('Diapositive suivante').first);
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);

    await tester.tap(find.byTooltip('Diapositive précédente').first);
    await tester.pumpAndSettle();
    expect(find.text('1 / 3'), findsOneWidget);
  });

  testWidgets(
    'le diaporama plein écran navigue et rapporte la diapositive en quittant',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: PresentationViewerScreen(pickSlides: _threeSlidesPicker)),
      );

      await tester.tap(find.text('Choisir des images'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Démarrer le diaporama'));
      await tester.pumpAndSettle();

      expect(find.text('1 / 3'), findsOneWidget);
      await tester.tap(find.byTooltip('Diapositive suivante').first);
      await tester.pumpAndSettle();
      expect(find.text('2 / 3'), findsOneWidget);

      await tester.tap(find.byTooltip('Quitter le diaporama'));
      await tester.pumpAndSettle();

      // De retour sur l'écran principal, resté synchronisé sur la diapositive 2.
      expect(find.text('2 / 3'), findsOneWidget);
      expect(find.text('Démarrer le diaporama'), findsOneWidget);
    },
  );
}
