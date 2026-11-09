import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:swvertex_camera_projector/core/mjpeg_client.dart';

/// Sert exactement le format produit par ScreenStreamService.kt
/// (`multipart/x-mixed-replace; boundary=frame`, une partie par trame, avec
/// Content-Length) depuis un vrai HttpServer en boucle locale.
Future<HttpServer> _startFakeStreamServer(List<Uint8List> frames) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((request) async {
    request.response.headers.set(
      'Content-Type',
      'multipart/x-mixed-replace; boundary=frame',
    );
    for (final frame in frames) {
      request.response.write('--frame\r\n');
      request.response.write('Content-Type: image/jpeg\r\n');
      request.response.write('Content-Length: ${frame.length}\r\n\r\n');
      request.response.add(frame);
      request.response.write('\r\n');
      await request.response.flush();
    }
    await request.response.close();
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
