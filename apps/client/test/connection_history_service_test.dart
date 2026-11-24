import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:swvertex_camera_projector/features/projection/connection_history.dart';
import 'package:swvertex_camera_projector/features/projection/connection_history_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('aucun historique au départ', () async {
    const service = ConnectionHistoryService();
    expect(await service.list(), isEmpty);
  });

  test('les événements ajoutés apparaissent du plus récent au plus ancien', () async {
    const service = ConnectionHistoryService();
    await service.add(
      ConnectionEvent(
        timestamp: DateTime(2026, 1, 1, 10, 0),
        type: ConnectionEventType.capture,
        target: '',
        outcome: ConnectionOutcome.started,
      ),
    );
    await service.add(
      ConnectionEvent(
        timestamp: DateTime(2026, 1, 1, 10, 5),
        type: ConnectionEventType.direct,
        target: 'PC du salon',
        outcome: ConnectionOutcome.connected,
      ),
    );

    final history = await service.list();
    expect(history, hasLength(2));
    expect(history.first.target, 'PC du salon');
    expect(history.last.type, ConnectionEventType.capture);
  });

  test('effacer vide l\'historique', () async {
    const service = ConnectionHistoryService();
    await service.add(
      ConnectionEvent(
        timestamp: DateTime.now(),
        type: ConnectionEventType.dlna,
        target: 'TV salon',
        outcome: ConnectionOutcome.error,
      ),
    );
    expect(await service.list(), isNotEmpty);

    await service.clear();
    expect(await service.list(), isEmpty);
  });

  test('ne garde que les maxEntries événements les plus récents', () async {
    const service = ConnectionHistoryService();
    for (var i = 0; i < ConnectionHistoryService.maxEntries + 5; i++) {
      await service.add(
        ConnectionEvent(
          timestamp: DateTime(2026, 1, 1).add(Duration(minutes: i)),
          type: ConnectionEventType.capture,
          target: '',
          outcome: ConnectionOutcome.started,
        ),
      );
    }

    final history = await service.list();
    expect(history, hasLength(ConnectionHistoryService.maxEntries));
    // Le plus récent (dernier ajouté) doit être en tête.
    expect(history.first.timestamp.minute, (ConnectionHistoryService.maxEntries + 4) % 60);
  });
}
