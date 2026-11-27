import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:swvertex_camera_projector/features/camera/camera_screen.dart';

void main() {
  testWidgets('écran non démarré : plein écran désactivé', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CameraScreen()));

    expect(find.text('Caméra non démarrée'), findsOneWidget);
    final fullscreen = tester.widget<FilledButton>(find.widgetWithIcon(FilledButton, Icons.fullscreen));
    expect(fullscreen.onPressed, isNull);
  });

  testWidgets('aucune caméra détectée affiche un message honnête', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: CameraScreen(listCameras: () async => const [])),
    );

    await tester.tap(find.text('Démarrer la caméra'));
    await tester.pumpAndSettle();

    expect(find.text('Aucune caméra détectée sur cet appareil.'), findsOneWidget);
    final fullscreen = tester.widget<FilledButton>(find.widgetWithIcon(FilledButton, Icons.fullscreen));
    expect(fullscreen.onPressed, isNull);
  });

  testWidgets(
    'aucun pilote caméra enregistré (plateforme non prise en charge) affiche un message honnête',
    (tester) async {
      // On laisse volontairement le vrai availableCameras() de la plateforme
      // réelle (pas de mock) : dans le banc de test Flutter, aucun pilote
      // caméra n'est enregistré, exactement comme sur Windows dans ce
      // prototype. L'écran doit surfacer cette erreur réelle honnêtement.
      // pumpAndSettle n'est pas utilisable ici : son algorithme de détection
      // d'inactivité n'interagit pas correctement avec runAsync pour ce vrai
      // rejet de canal de plateforme. On avance donc l'horloge réelle par
      // petits pas jusqu'à ce que le message d'erreur apparaisse.
      await tester.runAsync(() async {
        await tester.pumpWidget(const MaterialApp(home: CameraScreen()));

        await tester.tap(find.text('Démarrer la caméra'));
        for (var i = 0; i < 20; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          await tester.pump();
        }
      });

      expect(
        find.text(
          'Caméra non disponible sur cette plateforme dans ce prototype '
          '(aucun pilote caméra installé pour ce client).',
        ),
        findsOneWidget,
      );
      final fullscreen = tester.widget<FilledButton>(find.widgetWithIcon(FilledButton, Icons.fullscreen));
      expect(fullscreen.onPressed, isNull);
    },
  );
}
