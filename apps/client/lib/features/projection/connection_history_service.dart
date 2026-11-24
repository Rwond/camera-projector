import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'connection_history.dart';

/// Journal local des événements de connexion (démarrage/arrêt de capture,
/// connexion directe, diffusion vers un Space, cast DLNA). Purement local à
/// l'appareil, comme [SpacesService] — pas de synchronisation avec un
/// quelconque backend.
class ConnectionHistoryService {
  const ConnectionHistoryService();

  static const _key = 'swvertex.connection_history.v1';

  /// Nombre maximal d'événements conservés : au-delà, les plus anciens sont
  /// supprimés pour ne pas faire grossir le stockage local indéfiniment.
  static const maxEntries = 50;

  /// Les événements les plus récents en premier.
  Future<List<ConnectionEvent>> list() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const [];
    final decoded = jsonDecode(raw) as List;
    return decoded
        .map((e) => ConnectionEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> add(ConnectionEvent event) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await list();
    final updated = [event, ...current].take(maxEntries).toList();
    await prefs.setString(
      _key,
      jsonEncode(updated.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
