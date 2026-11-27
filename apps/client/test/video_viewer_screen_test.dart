import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';

import 'package:swvertex_camera_projector/features/videos/video_viewer_screen.dart';

Future<PickedVideo?> _cancelledPicker() async => null;

Future<PickedVideo?> _fakeNativePicker() async =>
    const PickedVideo(name: 'clip.mp4', path: 'fixtures/clip.mp4');

Future<PickedVideo?> _fakeWebPicker() async =>
    const PickedVideo(name: 'clip.mp4', path: null);

void main() {
  testWidgets('aucune vidéo choisie : le plein écran est désactivé', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: VideoViewerScreen(pickVideo: _cancelledPicker)),
    );

    expect(find.text('Aucune vidéo choisie'), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets(
    'sans chemin de fichier exploitable (Web), un message honnête remplace la lecture',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: VideoViewerScreen(pickVideo: _fakeWebPicker)),
      );

      await tester.tap(find.text('Choisir une vidéo'));
      await tester.pumpAndSettle();

      expect(find.textContaining('n\'est pas prise en charge depuis le navigateur'), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    },
  );

  testWidgets(
    'si l\'initialisation du lecteur échoue, un message honnête s\'affiche sans planter',
    (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: VideoViewerScreen(
              pickVideo: _fakeNativePicker,
              // Aucune implémentation de plateforme vidéo n'est enregistrée
              // dans l'environnement de test : l'initialisation échoue
              // réellement (pas un double simulé), exactement comme le reste
              // de ce projet laisse les échecs de plateforme se produire et
              // vérifie l'état honnête qui en résulte.
              controllerFactory: (file) => VideoPlayerController.file(file),
            ),
          ),
        );

        await tester.tap(find.text('Choisir une vidéo'));
        // Le délai de garde de l'écran est de 8 s : laisse assez de marge.
        await _pumpUntilFound(
          tester,
          find.textContaining('Aperçu vidéo indisponible'),
          maxAttempts: 150,
        );

        expect(find.textContaining('Aperçu vidéo indisponible'), findsOneWidget);
        final button = tester.widget<FilledButton>(find.byType(FilledButton));
        expect(button.onPressed, isNull);
      });
    },
  );
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxAttempts = 50,
}) async {
  for (var i = 0; i < maxAttempts; i++) {
    if (finder.evaluate().isNotEmpty) return;
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
  }
}
