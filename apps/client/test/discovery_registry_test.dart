import 'package:flutter_test/flutter_test.dart';

import 'package:swvertex_camera_projector/features/projection/discovery_service.dart';

void main() {
  group('encodeAnnouncement / decodeAnnouncement', () {
    test('round-trip conserve le nom et le port', () {
      final bytes = encodeAnnouncement(name: 'Salon', pairPort: 45681);
      final decoded = decodeAnnouncement(bytes);

      expect(decoded, isNotNull);
      expect(decoded!['name'], 'Salon');
      expect(decoded['pairPort'], 45681);
    });

    test('rejette un paquet qui n\'est pas une annonce swvertex', () {
      expect(decodeAnnouncement('{"type":"autre-chose"}'.codeUnits), isNull);
    });

    test('rejette un paquet non JSON sans planter', () {
      expect(decodeAnnouncement([1, 2, 3, 255, 254]), isNull);
    });
  });

  group('ReceiverRegistry', () {
    test('conserve un récepteur vu récemment', () {
      final registry = ReceiverRegistry(ttl: const Duration(seconds: 6));
      final now = DateTime(2026, 1, 1, 12);
      const receiver = DiscoveredReceiver(
        name: 'Salon',
        address: '192.168.1.10',
        pairPort: 45681,
      );

      registry.seen(receiver, now: now);
      final current = registry.prune(now: now.add(const Duration(seconds: 2)));

      expect(current, [receiver]);
    });

    test('retire un récepteur qui ne s\'est plus annoncé depuis le TTL', () {
      final registry = ReceiverRegistry(ttl: const Duration(seconds: 6));
      final now = DateTime(2026, 1, 1, 12);
      const receiver = DiscoveredReceiver(
        name: 'Salon',
        address: '192.168.1.10',
        pairPort: 45681,
      );

      registry.seen(receiver, now: now);
      final current = registry.prune(now: now.add(const Duration(seconds: 10)));

      expect(current, isEmpty);
    });

    test('une nouvelle annonce renouvelle la présence du récepteur', () {
      final registry = ReceiverRegistry(ttl: const Duration(seconds: 6));
      final now = DateTime(2026, 1, 1, 12);
      const receiver = DiscoveredReceiver(
        name: 'Salon',
        address: '192.168.1.10',
        pairPort: 45681,
      );

      registry.seen(receiver, now: now);
      registry.seen(receiver, now: now.add(const Duration(seconds: 5)));
      final current = registry.prune(now: now.add(const Duration(seconds: 9)));

      expect(current, [receiver]);
    });
  });
}
