import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:swvertex_camera_projector/features/lab/lab_home_screen.dart';

void main() {
  testWidgets('le menu labo donne accès aux modes B et C', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LabHomeScreen()));

    expect(find.text('Mode B — écran vers navigateur'), findsOneWidget);
    expect(find.text('Mode C — projection par lentille'), findsOneWidget);
    expect(
      find.text('Recevoir une projection (connexion directe)'),
      findsOneWidget,
    );
  });

  testWidgets('le bouton mode C ouvre l’écran lentille', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LabHomeScreen()));

    await tester.tap(find.text('Mode C — projection par lentille'));
    await tester.pumpAndSettle();

    expect(find.text('Projection par lentille (prototype)'), findsOneWidget);
  });
}
