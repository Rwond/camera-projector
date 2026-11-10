import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:swvertex_camera_projector/features/projection/discovery_service.dart';
import 'package:swvertex_camera_projector/features/projection/pairing_service.dart';
import 'package:swvertex_camera_projector/features/projection/projection_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(
    'com.swvertex.camera_projector/projection_test',
  );
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  // Ces tests parlent à de vraies sockets (boucle locale) : voir la note de
  // test/receiver_screen_test.dart sur WidgetTester.runAsync.

  testWidgets(
    'se connecter à un récepteur détecté envoie l\'URL /stream et affiche "Connecté"',
    (tester) async {
      await tester.runAsync(() async {
        messenger.setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'status') {
            return <String, dynamic>{
              'running': true,
              'ip': '192.168.1.42',
              'port': 8080,
              'url': 'http://192.168.1.42:8080/',
            };
          }
          return null;
        });

        final server = PairingServer();
        final port = await server.start();
        addTearDown(server.stop);

        PairingRequest? received;
        final sub = server.incomingRequests.listen((pending) {
          received = pending.request;
          pending.respond(true);
        });
        addTearDown(sub.cancel);

        final receiver = DiscoveredReceiver(
          name: 'PC du salon',
          address: InternetAddress.loopbackIPv4.address,
          pairPort: port,
        );

        tester.view.physicalSize = const Size(800, 2400);
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

        expect(find.text('PC du salon'), findsOneWidget);

        await tester.tap(find.text('Se connecter'));
        await _pumpUntilFound(tester, find.text('Connecté'));

        expect(received, isNotNull);
        expect(received!.streamUrl, 'http://192.168.1.42:8080/stream');
      });
    },
  );

  testWidgets('un refus du récepteur affiche un message d\'erreur', (
    tester,
  ) async {
    await tester.runAsync(() async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'status') {
          return <String, dynamic>{
            'running': true,
            'ip': '192.168.1.42',
            'port': 8080,
            'url': 'http://192.168.1.42:8080/',
          };
        }
        return null;
      });

      final server = PairingServer();
      final port = await server.start();
      addTearDown(server.stop);

      final sub = server.incomingRequests.listen((pending) {
        pending.respond(false);
      });
      addTearDown(sub.cancel);

      final receiver = DiscoveredReceiver(
        name: 'PC du salon',
        address: InternetAddress.loopbackIPv4.address,
        pairPort: port,
      );

      tester.view.physicalSize = const Size(800, 2400);
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
      await _pumpUntilFound(
        tester,
        find.text('Connexion refusée par PC du salon.'),
      );
    });
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
