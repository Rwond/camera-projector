import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:swvertex_camera_projector/features/projection/discovery_service.dart';
import 'package:swvertex_camera_projector/features/projection/pairing_service.dart';
import 'package:swvertex_camera_projector/features/projection/projection_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.swvertex.camera_projector/projection_test');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  testWidgets(
    'une connexion directe apparaît dans le diagnostic et l\'historique, et demande '
    'confirmation avant d\'arrêter',
    (tester) async {
      await tester.runAsync(() async {
        var isRunning = true;
        messenger.setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'stop') {
            isRunning = false;
            return null;
          }
          if (call.method == 'status') {
            return isRunning
                ? <String, dynamic>{
                    'running': true,
                    'ip': '192.168.1.42',
                    'port': 8080,
                    'url': 'http://192.168.1.42:8080/',
                  }
                : <String, dynamic>{'running': false};
          }
          return null;
        });

        final server = PairingServer();
        final port = await server.start();
        addTearDown(server.stop);

        final sub = server.incomingRequests.listen((pending) => pending.respond(true));
        addTearDown(sub.cancel);

        final receiver = DiscoveredReceiver(
          name: 'PC du salon',
          address: InternetAddress.loopbackIPv4.address,
          pairPort: port,
        );

        tester.view.physicalSize = const Size(800, 3000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            home: ProjectionScreen(
              isAndroidOverride: true,
              enableScanning: false,
              receiversOverride: [receiver],
            ),
          ),
        );
        await tester.pump();
        await tester.pump();

        await tester.tap(find.text('Se connecter'));
        await _pumpUntilFound(tester, find.text('Connecté'));

        expect(find.text('Diagnostic en direct'), findsOneWidget);
        expect(find.textContaining('Connexions actives : 1'), findsOneWidget);
        expect(find.text('PC du salon (Connexion directe) : connecté'), findsOneWidget);

        // Arrêter alors qu'une connexion est active doit demander confirmation.
        await tester.tap(find.text('Arrêter la capture'));
        await tester.pumpAndSettle();

        expect(find.text('Arrêter la capture ?'), findsOneWidget);

        await tester.tap(find.text('Annuler'));
        await tester.pumpAndSettle();
        expect(find.text('Capture active'), findsOneWidget);

        await tester.tap(find.text('Arrêter la capture'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Arrêter'));
        await _pumpUntilFound(tester, find.text('Capture arrêtée'));

        expect(find.text('Diagnostic en direct'), findsNothing);
        expect(find.textContaining('Capture arrêtée'), findsAtLeastNWidgets(1));
      });
    },
  );

  testWidgets('sans aucun événement, l\'historique affiche un état vide honnête', (tester) async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'status') return <String, dynamic>{'running': false};
      return null;
    });

    tester.view.physicalSize = const Size(800, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: ProjectionScreen(isAndroidOverride: true, enableScanning: false),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aucun événement encore.'), findsOneWidget);
    expect(find.text('Effacer'), findsNothing);
  });
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
