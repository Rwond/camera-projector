import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:swvertex_camera_projector/features/lens/lens_brightness_service.dart';
import 'package:swvertex_camera_projector/features/lens/lens_projection_screen.dart';

class _FakeBrightnessService extends LensBrightnessService {
  const _FakeBrightnessService(this.calls);

  final List<String> calls;

  @override
  Future<bool> maximize() async {
    calls.add('maximize');
    return true;
  }

  @override
  Future<void> restore() async {
    calls.add('restore');
  }
}

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

Future<Uint8List?> _fakePicker() async {
  return Uint8List.fromList(_onePixelPng);
}

Future<Uint8List?> _cancelledPicker() async => null;

void main() {
  testWidgets('affiche le motif de calibrage par défaut et le mode 180°', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LensProjectionScreen(pickImage: _cancelledPicker),
      ),
    );

    expect(find.text('Aucune image : motif de calibrage'), findsOneWidget);
    expect(find.text('180° (horizontal + vertical)'), findsOneWidget);
  });

  testWidgets('choisir une image affiche son aperçu', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: LensProjectionScreen(pickImage: _fakePicker)),
    );

    await tester.tap(find.text('Choisir une image'));
    await tester.pumpAndSettle();

    expect(find.text('Aucune image : motif de calibrage'), findsNothing);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets(
    'démarrer la projection maximise la luminosité puis la restaure en quittant',
    (tester) async {
      final calls = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: LensProjectionScreen(
            pickImage: _cancelledPicker,
            brightness: _FakeBrightnessService(calls),
          ),
        ),
      );

      await tester.tap(find.text('Démarrer la projection'));
      await tester.pumpAndSettle();

      expect(calls, contains('maximize'));
      expect(find.text('Touchez l\'écran pour quitter'), findsOneWidget);

      await tester.tap(find.text('Touchez l\'écran pour quitter'));
      await tester.pumpAndSettle();

      expect(calls, containsAllInOrder(['maximize', 'restore']));
    },
  );
}
