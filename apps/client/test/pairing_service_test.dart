import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:swvertex_camera_projector/features/projection/pairing_service.dart';

void main() {
  // Vraies sockets en boucle locale (127.0.0.1) : fiable en sandbox/CI,
  // contrairement à la diffusion UDP réseau (voir discovery_service.dart).
  test('le récepteur qui accepte renvoie "accepted: true" à l\'émetteur', () async {
    final server = PairingServer();
    final port = await server.start();
    addTearDown(server.stop);

    final sub = server.incomingRequests.listen((pending) {
      expect(pending.request.fromName, 'Téléphone de test');
      expect(pending.request.streamUrl, 'http://127.0.0.1:8080/stream');
      pending.respond(true);
    });
    addTearDown(sub.cancel);

    const client = PairingClient();
    final accepted = await client.requestConnection(
      receiverAddress: InternetAddress.loopbackIPv4,
      receiverPort: port,
      fromName: 'Téléphone de test',
      streamUrl: 'http://127.0.0.1:8080/stream',
    );

    expect(accepted, isTrue);
  });

  test('le récepteur qui refuse renvoie "accepted: false"', () async {
    final server = PairingServer();
    final port = await server.start();
    addTearDown(server.stop);

    final sub = server.incomingRequests.listen((pending) {
      pending.respond(false);
    });
    addTearDown(sub.cancel);

    const client = PairingClient();
    final accepted = await client.requestConnection(
      receiverAddress: InternetAddress.loopbackIPv4,
      receiverPort: port,
      fromName: 'Téléphone de test',
      streamUrl: 'http://127.0.0.1:8080/stream',
    );

    expect(accepted, isFalse);
  });

  test('une demande sans réponse est refusée après expiration', () async {
    final server = PairingServer(requestTimeout: const Duration(milliseconds: 200));
    final port = await server.start();
    addTearDown(server.stop);

    // On écoute mais on ne répond jamais : le serveur doit refuser tout
    // seul après le délai plutôt que de bloquer la connexion indéfiniment.
    final sub = server.incomingRequests.listen((_) {});
    addTearDown(sub.cancel);

    const client = PairingClient();
    final accepted = await client.requestConnection(
      receiverAddress: InternetAddress.loopbackIPv4,
      receiverPort: port,
      fromName: 'Téléphone de test',
      streamUrl: 'http://127.0.0.1:8080/stream',
    );

    expect(accepted, isFalse);
  });
}
