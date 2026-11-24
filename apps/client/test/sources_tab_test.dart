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
