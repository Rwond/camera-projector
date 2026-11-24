import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:swvertex_camera_projector/features/projection/discovery_service.dart';
import 'package:swvertex_camera_projector/features/projection/pairing_service.dart';
import 'package:swvertex_camera_projector/features/projection/projection_screen.dart';
import 'package:swvertex_camera_projector/features/spaces/space.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.swvertex.camera_projector/projection_test');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  testWidgets('diffuser vers un Space connecte le membre en ligne et marque l\'autre hors ligne', (
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

      PairingRequest? received;
      final sub = server.incomingRequests.listen((pending) {
        received = pending.request;
        pending.respond(true);
      });
      addTearDown(sub.cancel);

      final onlineReceiver = DiscoveredReceiver(
        name: 'PC du salon',
        address: InternetAddress.loopbackIPv4.address,
        pairPort: port,
      );
      final space = Space(
        id: 'space-1',
        name: 'Salon',
        members: const [
          SpaceMember(name: 'PC du salon', lastAddress: '10.0.0.1', lastPairPort: 1),
          SpaceMember(name: 'TV chambre', lastAddress: '10.0.0.2', lastPairPort: 2),
        ],
      );

      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: ProjectionScreen(
            isAndroidOverride: true,
            enableScanning: false,
            receiversOverride: [onlineReceiver],
            spacesOverride: [space],
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Salon (2 membres)'), findsOneWidget);

      await tester.tap(find.text('Diffuser'));
      await _pumpUntilFound(tester, find.text('TV chambre : hors ligne (non détecté sur le réseau)'));

      expect(find.text('PC du salon : connecté'), findsOneWidget);
      expect(received, isNotNull);
      expect(received!.streamUrl, 'http://192.168.1.42:8080/stream');
    });
  });
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder, {int maxAttempts = 50}) async {
  for (var i = 0; i < maxAttempts; i++) {
    if (finder.evaluate().isNotEmpty) return;
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
  }
}
