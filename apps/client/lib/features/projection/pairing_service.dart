import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Demande de connexion envoyée par l'émetteur (téléphone) à un récepteur
/// découvert sur le réseau local, pour projeter directement dans
/// l'application réceptrice plutôt que dans un navigateur.
class PairingRequest {
  const PairingRequest({required this.fromName, required this.streamUrl});

  factory PairingRequest.fromJson(Map<String, dynamic> json) {
    return PairingRequest(
      fromName: json['from'] as String? ?? 'Appareil inconnu',
      streamUrl: json['streamUrl'] as String? ?? '',
    );
  }

  final String fromName;
  final String streamUrl;

  Map<String, dynamic> toJson() => {'from': fromName, 'streamUrl': streamUrl};
}

/// Lit une ligne `\n`-terminée sur un socket, avec expiration pour ne jamais
/// bloquer indéfiniment sur une connexion muette ou mal formée.
Future<String?> _readLine(
  Socket socket, {
  Duration timeout = const Duration(seconds: 8),
}) async {
  final completer = Completer<String?>();
  final buffer = <int>[];
  late final StreamSubscription<List<int>> subscription;
  subscription = socket.listen(
    (data) {
      buffer.addAll(data);
      final i = buffer.indexOf(10); // '\n'
      if (i != -1 && !completer.isCompleted) {
        completer.complete(utf8.decode(buffer.sublist(0, i)));
        subscription.cancel();
      }
    },
    onDone: () {
      if (!completer.isCompleted) completer.complete(null);
    },
    onError: (Object e) {
      if (!completer.isCompleted) completer.completeError(e);
    },
  );
  return completer.future.timeout(timeout, onTimeout: () => null);
}

/// Une demande entrante en attente de décision : l'appelant (l'écran
/// récepteur) affiche une boîte de dialogue puis appelle [respond].
class PendingPairingRequest {
  PendingPairingRequest(this.request, this._completer);

  final PairingRequest request;
  final Completer<bool> _completer;

  void respond(bool accepted) {
    if (!_completer.isCompleted) _completer.complete(accepted);
  }
}

/// Côté récepteur : écoute les demandes de connexion entrantes sur un port
/// TCP et les expose via [incomingRequests], pour que l'interface décide de
/// les accepter (ex. boîte de dialogue « X souhaite projeter sur cet
/// écran »). Une demande sans réponse sous [requestTimeout] est refusée
/// automatiquement plutôt que de bloquer la connexion indéfiniment.
class PairingServer {
  PairingServer({this.requestTimeout = const Duration(seconds: 30)});

  final Duration requestTimeout;
  ServerSocket? _server;
  final _controller = StreamController<PendingPairingRequest>.broadcast();

  int? get port => _server?.port;

  Stream<PendingPairingRequest> get incomingRequests => _controller.stream;

  Future<int> start({int port = 0}) async {
    final server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
    _server = server;
    server.listen(_handleConnection);
    return server.port;
  }

  Future<void> _handleConnection(Socket socket) async {
    try {
      final line = await _readLine(socket);
      if (line == null) return;
      final request = PairingRequest.fromJson(
        jsonDecode(line) as Map<String, dynamic>,
      );
      final completer = Completer<bool>();
      _controller.add(PendingPairingRequest(request, completer));
      final accepted = await completer.future.timeout(
        requestTimeout,
        onTimeout: () => false,
      );
      socket.add(utf8.encode('${jsonEncode({'accepted': accepted})}\n'));
      await socket.flush();
    } catch (_) {
      // Connexion mal formée ou fermée prématurément : ignorée.
    } finally {
      await socket.close();
    }
  }

  Future<void> stop() async {
    await _server?.close();
    _server = null;
    await _controller.close();
  }
}

/// Côté émetteur : envoie une demande de connexion à un récepteur et attend
/// sa décision (accepté/refusé).
class PairingClient {
  const PairingClient();

  Future<bool> requestConnection({
    required InternetAddress receiverAddress,
    required int receiverPort,
    required String fromName,
    required String streamUrl,
  }) async {
    final socket = await Socket.connect(
      receiverAddress,
      receiverPort,
      timeout: const Duration(seconds: 5),
    );
    try {
      final request = PairingRequest(fromName: fromName, streamUrl: streamUrl);
      socket.add(utf8.encode('${jsonEncode(request.toJson())}\n'));
      await socket.flush();
      final line = await _readLine(socket);
      if (line == null) return false;
      final response = jsonDecode(line) as Map<String, dynamic>;
      return response['accepted'] == true;
    } finally {
      await socket.close();
    }
  }
}
