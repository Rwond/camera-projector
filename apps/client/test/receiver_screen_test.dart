import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:swvertex_camera_projector/features/projection/pairing_service.dart';
import 'package:swvertex_camera_projector/features/projection/receiver_screen.dart';

Future<HttpServer> _startFakeStreamServer(Uint8List frame) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((request) async {
    request.response.headers.set(
      'Content-Type',
      'multipart/x-mixed-replace; boundary=frame',
    );
    request.response.write('--frame\r\n');
    request.response.write('Content-Type: image/jpeg\r\n');
    request.response.write('Content-Length: ${frame.length}\r\n\r\n');
    request.response.add(frame);
    request.response.write('\r\n');
    await request.response.close();
  });
  return server;
}

// PNG 1x1 valide, réutilisé pour que l'écran visionneuse puisse réellement
// décoder une trame (voir test/lens_projection_screen_test.dart).
const _onePixelPng = [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
];

void main() {
  // Ces écrans parlent à de vraies sockets (boucle locale) : le travail
  // réseau doit tourner dans runAsync, sinon l'horloge figée des tests
  // Flutter ne le laisse jamais progresser (voir doc de WidgetTester.runAsync).
  testWidgets(
    'accepter une demande entrante ouvre la visionneuse du flux',
    (tester) async {
      await tester.runAsync(() async {
        final frame = Uint8List.fromList(_onePixelPng);
        final streamServer = await _startFakeStreamServer(frame);
        addTearDown(streamServer.close);

        final server = PairingServer();
        await tester.pumpWidget(
          MaterialApp(
            home: ReceiverScreen(
              pairingServer: server,
              deviceName: 'PC du salon',
              enableAnnouncer: false,
            ),
          ),
        );
        await tester.pump();

        expect(find.text('PC du salon'), findsOneWidget);
        expect(server.port, isNotNull);

        const client = PairingClient();
        final connectionFuture = client.requestConnection(
          receiverAddress: InternetAddress.loopbackIPv4,
          receiverPort: server.port!,
          fromName: 'Téléphone de test',
          streamUrl: 'http://127.0.0.1:${streamServer.port}/stream',
        );

        // Laisse la demande réseau réelle arriver jusqu'à la boîte de dialogue.
        await _pumpUntilFound(
          tester,
          find.text(
            '« Téléphone de test » souhaite projeter sur cet écran. Accepter ?',
          ),
        );

        await tester.tap(find.text('Accepter'));
        await tester.pump();
        await tester.pump();

        expect(await connectionFuture, isTrue);

        await _pumpUntilFound(
          tester,
          find.text('Projection depuis Téléphone de test'),
        );
      });
    },
  );

  testWidgets('refuser une demande entrante ne quitte pas l\'écran d\'attente', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final server = PairingServer();
      await tester.pumpWidget(
        MaterialApp(
          home: ReceiverScreen(
            pairingServer: server,
            deviceName: 'PC du salon',
            enableAnnouncer: false,
          ),
        ),
      );
      await tester.pump();

      const client = PairingClient();
      final connectionFuture = client.requestConnection(
        receiverAddress: InternetAddress.loopbackIPv4,
        receiverPort: server.port!,
        fromName: 'Téléphone de test',
        streamUrl: 'http://127.0.0.1:9/stream',
      );

      await _pumpUntilFound(tester, find.text('Refuser'));
      await tester.tap(find.text('Refuser'));
      await tester.pump();

      expect(await connectionFuture, isFalse);
      expect(
        find.text('En attente d\'une demande de connexion…'),
        findsOneWidget,
      );
    });
  });
}

/// Pompe des frames en laissant de vrais délais s'écouler, le temps qu'une
/// opération réseau réelle (hors horloge des tests) fasse progresser l'UI.
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
