import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:swvertex_camera_projector/features/home/spaces_tab.dart';
import 'package:swvertex_camera_projector/features/projection/discovery_service.dart';
import 'package:swvertex_camera_projector/features/spaces/space.dart';
import 'package:swvertex_camera_projector/features/spaces/spaces_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('aucun Space : état honnête, pas de fausse liste', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SpacesTab(enableScanning: false, receiversOverride: [])),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aucun Space encore créé'), findsOneWidget);
  });

  testWidgets('ajouter un récepteur détecté crée un Space et l\'affiche avec son membre en ligne', (
    tester,
  ) async {
    const receiver = DiscoveredReceiver(name: 'PC du salon', address: '192.168.1.10', pairPort: 4000);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SpacesTab(enableScanning: false, receiversOverride: [receiver])),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PC du salon'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.playlist_add));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Salon');
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();

    expect(find.text('Salon'), findsOneWidget);
    expect(find.text('1/1 en ligne'), findsOneWidget);

    final service = const SpacesService();
    final spaces = await service.list();
    expect(spaces.single.members.single.name, 'PC du salon');
  });

  testWidgets('un membre enregistré mais plus détecté sur le réseau est hors ligne', (
    tester,
  ) async {
    final service = const SpacesService();
    final space = await service.create('Salon');
    await service.addMember(
      space.id,
      const SpaceMember(name: 'PC du salon', lastAddress: '192.168.1.10', lastPairPort: 4000),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SpacesTab(enableScanning: false, receiversOverride: [])),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('0/1 en ligne'), findsOneWidget);
  });
}
