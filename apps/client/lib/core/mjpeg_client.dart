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

/// Ouvre une connexion HTTP vers un flux MJPEG `/stream` et expose les trames
/// JPEG décodées. Une classe (plutôt qu'une fonction libre) pour rester
/// injectable/remplaçable dans les tests comme les autres services réseau du
/// projet.
class MjpegClient {
  const MjpegClient();

  Stream<Uint8List> frames(Uri streamUri) {
    final controller = StreamController<Uint8List>();
    HttpClient? client;

    controller.onListen = () async {
      client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
      try {
        final request = await client!.getUrl(streamUri);
        final response = await request.close();
        if (response.statusCode != HttpStatus.ok) {
          controller.addError(
            HttpException('Statut HTTP ${response.statusCode}'),
          );
          await controller.close();
          return;
        }
        await for (final frame in parseMultipartJpeg(response)) {
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
    controller.onCancel = () => client?.close(force: true);

    return controller.stream;
  }
}
