import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Découpe un flux `multipart/x-mixed-replace` (celui servi par
/// `ScreenStreamService.kt` sur `/stream`, boundary `frame`, toujours avec un
/// en-tête `Content-Length`) en trames JPEG individuelles.
///
/// Permet d'afficher le flux directement dans l'application (via
/// [Image.memory]) sans passer par un `<img>` de navigateur.
Stream<Uint8List> parseMultipartJpeg(Stream<List<int>> byteStream) async* {
  const headerEnd = [13, 10, 13, 10]; // \r\n\r\n
  final buffer = <int>[];

  await for (final chunk in byteStream) {
    buffer.addAll(chunk);

    while (true) {
      final headerEndIndex = _indexOfSequence(buffer, headerEnd);
      if (headerEndIndex == -1) {
        // Évite une accumulation illimitée si le flux envoie n'importe quoi.
        if (buffer.length > 1 << 20) buffer.clear();
        break;
      }

      final headerText = latin1.decode(buffer.sublist(0, headerEndIndex));
      final match = RegExp(
        r'Content-Length:\s*(\d+)',
        caseSensitive: false,
      ).firstMatch(headerText);

      if (match == null) {
        buffer.removeRange(0, headerEndIndex + headerEnd.length);
        continue;
      }

      final length = int.parse(match.group(1)!);
      final frameStart = headerEndIndex + headerEnd.length;
      final frameEnd = frameStart + length;
      if (buffer.length < frameEnd) break; // trame incomplète, attendre la suite

      yield Uint8List.fromList(buffer.sublist(frameStart, frameEnd));

      var consumedEnd = frameEnd;
      if (buffer.length >= frameEnd + 2 &&
          buffer[frameEnd] == 13 &&
          buffer[frameEnd + 1] == 10) {
        consumedEnd += 2;
      }
      buffer.removeRange(0, consumedEnd);
    }
  }
}

int _indexOfSequence(List<int> haystack, List<int> needle) {
  final limit = haystack.length - needle.length;
  outer:
  for (var i = 0; i <= limit; i++) {
    for (var j = 0; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) continue outer;
    }
    return i;
  }
  return -1;
}

/// Retire la ligne de statut et les en-têtes de la réponse HTTP elle-même
/// (jusqu'au premier `\r\n\r\n`), pour ne transmettre au parseur multipart
/// que le corps de la réponse.
Stream<List<int>> _stripHttpResponseHeaders(Stream<List<int>> raw) async* {
  const headerEnd = [13, 10, 13, 10];
  final buffer = <int>[];
  var stripped = false;

  await for (final chunk in raw) {
    if (stripped) {
      yield chunk;
      continue;
    }
    buffer.addAll(chunk);
    final index = _indexOfSequence(buffer, headerEnd);
    if (index != -1) {
      stripped = true;
      yield buffer.sublist(index + headerEnd.length);
    }
  }
}

/// Ouvre une connexion vers un flux MJPEG `/stream` et expose les trames
/// JPEG décodées. Une classe (plutôt qu'une fonction libre) pour rester
/// injectable/remplaçable dans les tests comme les autres services réseau du
/// projet.
///
/// Utilise une socket brute plutôt que `HttpClient` : le serveur natif
/// Android (`ScreenStreamService.kt`) n'annonce ni `Content-Length` ni
/// `Transfer-Encoding: chunked` pour le corps global de la réponse — sa fin
/// n'est signalée que par la fermeture de la connexion, ce qui n'arrive
/// jamais tant que le flux est actif. Un navigateur gère ce cas (c'est le
/// mode de fonctionnement standard du MJPEG), mais `dart:io HttpClient` ne
/// livre aucune donnée tant que la connexion n'est pas fermée — vérifié en
/// conditions réelles : le flux s'affichait dans un navigateur mais jamais
/// via `HttpClient`. La socket brute n'a pas ce problème : on lit les octets
/// au fur et à mesure qu'ils arrivent, sans attendre une longueur connue.
class MjpegClient {
  const MjpegClient();

  Stream<Uint8List> frames(Uri streamUri) {
    final controller = StreamController<Uint8List>();
    Socket? socket;

    controller.onListen = () async {
      try {
        socket = await Socket.connect(
          streamUri.host,
          streamUri.port,
          timeout: const Duration(seconds: 5),
        );
        final path = streamUri.path.isEmpty ? '/' : streamUri.path;
        socket!.write(
          'GET $path HTTP/1.1\r\n'
          'Host: ${streamUri.host}\r\n'
          'Connection: close\r\n\r\n',
        );
        final body = _stripHttpResponseHeaders(socket!);
        await for (final frame in parseMultipartJpeg(body)) {
          if (controller.isClosed) return;
          controller.add(frame);
        }
        await controller.close();
      } catch (e) {
        if (!controller.isClosed) {
          controller.addError(e);
          await controller.close();
        }
      }
    };
    controller.onCancel = () => socket?.destroy();

    return controller.stream;
  }
}
