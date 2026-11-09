import 'dart:async';
import 'dart:convert';
import 'dart:io';

const _announceType = 'swvertex-receiver';

/// Un récepteur annoncé sur le réseau local, prêt à recevoir une demande de
/// projection directe (voir [PairingServer] dans pairing_service.dart).
class DiscoveredReceiver {
  const DiscoveredReceiver({
    required this.name,
    required this.address,
    required this.pairPort,
  });

  final String name;
  final String address;
  final int pairPort;

  String get key => '$address:$pairPort';

  @override
  bool operator ==(Object other) =>
      other is DiscoveredReceiver &&
      other.name == name &&
      other.address == address &&
      other.pairPort == pairPort;

  @override
  int get hashCode => Object.hash(name, address, pairPort);
}

Map<String, dynamic>? decodeAnnouncement(List<int> bytes) {
  try {
    final map = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    if (map['type'] != _announceType) return null;
    return map;
  } catch (_) {
    return null;
  }
}

List<int> encodeAnnouncement({required String name, required int pairPort}) {
  return utf8.encode(
    jsonEncode({'type': _announceType, 'name': name, 'pairPort': pairPort}),
  );
}

/// Logique pure (sans réseau) de suivi des récepteurs vus récemment : un
/// récepteur disparaît de la liste s'il cesse de s'annoncer, sans dépendre
/// d'une vraie socket — ce qui la rend testable indépendamment de l'aléa
/// réseau (diffusion UDP non garantie, pare-feu, etc.).
class ReceiverRegistry {
  ReceiverRegistry({this.ttl = const Duration(seconds: 6)});

  final Duration ttl;
  final _lastSeen = <String, DiscoveredReceiver>{};
  final _lastSeenAt = <String, DateTime>{};

  void seen(DiscoveredReceiver receiver, {DateTime? now}) {
    _lastSeen[receiver.key] = receiver;
    _lastSeenAt[receiver.key] = now ?? DateTime.now();
  }

  List<DiscoveredReceiver> prune({DateTime? now}) {
    final cutoff = (now ?? DateTime.now()).subtract(ttl);
    _lastSeenAt.removeWhere((key, seenAt) {
      final expired = seenAt.isBefore(cutoff);
      if (expired) _lastSeen.remove(key);
      return expired;
    });
    return current;
  }

  List<DiscoveredReceiver> get current => _lastSeen.values.toList();
}

/// Annonce périodiquement ce poste comme récepteur disponible (diffusion UDP
/// locale). Non vérifié sur un vrai réseau multi-appareils dans cet
/// environnement de développement — voir STATUS.md.
class ReceiverAnnouncer {
  ReceiverAnnouncer({
    required this.name,
    required this.pairPort,
    this.broadcastPort = 45680,
    this.interval = const Duration(seconds: 2),
  });

  final String name;
  final int pairPort;
  final int broadcastPort;
  final Duration interval;

  RawDatagramSocket? _socket;
  Timer? _timer;

  Future<void> start() async {
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    socket.broadcastEnabled = true;
    _socket = socket;
    _announce();
    _timer = Timer.periodic(interval, (_) => _announce());
  }

  void _announce() {
    final payload = encodeAnnouncement(name: name, pairPort: pairPort);
    try {
      _socket?.send(payload, InternetAddress('255.255.255.255'), broadcastPort);
    } catch (_) {
      // Diffusion indisponible sur ce réseau (ex. isolation Wi-Fi) : on
      // réessaiera au prochain intervalle plutôt que de planter.
    }
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _socket?.close();
    _socket = null;
  }
}

/// Écoute les annonces de récepteurs et expose la liste de ceux vus
/// récemment.
class ReceiverScanner {
  ReceiverScanner({this.broadcastPort = 45680, Duration? ttl})
    : _registry = ReceiverRegistry(ttl: ttl ?? const Duration(seconds: 6));

  final int broadcastPort;
  final ReceiverRegistry _registry;

  RawDatagramSocket? _socket;
  Timer? _pruneTimer;
  final _controller = StreamController<List<DiscoveredReceiver>>.broadcast();

  Stream<List<DiscoveredReceiver>> get receivers => _controller.stream;

  Future<void> start() async {
    final socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      broadcastPort,
      reuseAddress: true,
    );
    _socket = socket;
    socket.listen(_onEvent);
    _pruneTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _controller.add(_registry.prune());
    });
  }

  void _onEvent(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;
    final datagram = _socket?.receive();
    if (datagram == null) return;
    final map = decodeAnnouncement(datagram.data);
    if (map == null) return;
    final pairPort = map['pairPort'];
    if (pairPort is! num) return;
    _registry.seen(
      DiscoveredReceiver(
        name: map['name'] as String? ?? 'Récepteur',
        address: datagram.address.address,
        pairPort: pairPort.toInt(),
      ),
    );
    _controller.add(_registry.current);
  }

  Future<void> stop() async {
    _pruneTimer?.cancel();
    _pruneTimer = null;
    _socket?.close();
    _socket = null;
    await _controller.close();
  }
}
