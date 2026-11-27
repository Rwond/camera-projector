import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:swvertex_camera_projector/features/home/sources_tab.dart';

void main() {
  testWidgets('Photos est disponible et ouvre la visionneuse', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SourcesTab()));

    expect(find.text('Disponible'), findsAtLeastNWidgets(1));

    await tester.tap(find.text('Photos'));
    await tester.pumpAndSettle();

    expect(find.text('Photo à afficher'), findsOneWidget);
  });

  testWidgets('Vidéos est disponible et ouvre la visionneuse', (tester) async {
    // Grille virtualisée (GridView.builder) : les tuiles plus bas (Vidéos,
    // Documents) ont besoin d'un viewport assez grand pour être réalisées,
    // sinon le Finder ne les trouve pas (même principe que les écrans à
    // défilement du mode B, voir projection_screen_test.dart).
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: SourcesTab()));

    await tester.tap(find.text('Vidéos'));
    await tester.pumpAndSettle();

    expect(find.text('Vidéo à lire'), findsOneWidget);
  });

  testWidgets('Documents est disponible et ouvre la visionneuse', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: SourcesTab()));

    await tester.tap(find.text('Documents'));
    await tester.pumpAndSettle();

    expect(find.text('Document à afficher'), findsOneWidget);
  });

  testWidgets('un type non implémenté affiche un message honnête au lieu d\'ouvrir un écran', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SourcesTab())),
    );

    await tester.tap(find.text('Caméra'));
    await tester.pump();

    expect(find.text('Caméra : pas encore implémenté.'), findsOneWidget);
  });
}
