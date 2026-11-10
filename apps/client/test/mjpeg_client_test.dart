import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:swvertex_camera_projector/core/mjpeg_client.dart';

/// Reproduit fidèlement le format brut produit par ScreenStreamService.kt :
/// une socket brute, sans `Content-Length` ni `Transfer-Encoding: chunked`
/// pour le corps global (seules les parties en ont un) — la fin du flux
/// n'est signalée que par la fermeture de la connexion. Un `dart:io
/// HttpServer` ajoute automatiquement un chunked encoding dans ce cas, ce
/// qui masquerait le bug réel (vérifié sur matériel : le flux s'affichait
/// dans un navigateur mais jamais via `HttpClient`, qui attend une longueur
/// de corps déterminée). D'où une socket brute ici aussi, pour que ce test
/// aurait vraiment détecté le problème.
Future<ServerSocket> _startFakeStreamServer(List<Uint8List> frames) async {
  final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((client) async {
    // La requête du client n'est jamais lue, comme sur le vrai serveur
    // Android qui ne lit que la ligne de requête — le reste importe peu ici.
    client.write(
      'HTTP/1.1 200 OK\r\n'
      'Content-Type: multipart/x-mixed-replace; boundary=frame\r\n'
      'Connection: close\r\n\r\n',
    );
    for (final frame in frames) {
      client.write('--frame\r\n');
      client.write('Content-Type: image/jpeg\r\n');
      client.write('Content-Length: ${frame.length}\r\n\r\n');
      client.add(frame);
      client.write('\r\n');
      await client.flush();
    }
    await client.close();
  });
  return server;
}

void main() {
  test('extrait chaque trame JPEG du flux multipart', () async {
    final frameA = Uint8List.fromList([1, 2, 3, 4, 5]);
    final frameB = Uint8List.fromList(List.generate(300, (i) => i % 256));
    final server = await _startFakeStreamServer([frameA, frameB]);
    addTearDown(server.close);

    const client = MjpegClient();
    final frames = await client
        .frames(Uri.parse('http://127.0.0.1:${server.port}/stream'))
        .toList();

    expect(frames, hasLength(2));
    expect(frames[0], frameA);
    expect(frames[1], frameB);
  });

  test('gère un flux vide sans planter', () async {
    final server = await _startFakeStreamServer([]);
    addTearDown(server.close);

    const client = MjpegClient();
    final frames = await client
        .frames(Uri.parse('http://127.0.0.1:${server.port}/stream'))
        .toList();

    expect(frames, isEmpty);
  });

  test('parseMultipartJpeg recolle une trame coupée en plusieurs paquets réseau', () async {
    final frame = Uint8List.fromList(List.generate(50, (i) => i));
    final part = '--frame\r\nContent-Type: image/jpeg\r\nContent-Length: ${frame.length}\r\n\r\n';

    // Simule une trame qui arrive en plusieurs morceaux TCP, comme un vrai
    // flux réseau le ferait.
    final chunks = <List<int>>[
      part.codeUnits.sublist(0, 10),
      part.codeUnits.sublist(10),
      frame.sublist(0, 20),
      frame.sublist(20),
      [13, 10],
    ];

    final result = await parseMultipartJpeg(Stream.fromIterable(chunks)).toList();

    expect(result, hasLength(1));
    expect(result.single, frame);
  });
}
