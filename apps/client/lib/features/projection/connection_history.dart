/// Type de ce qui a déclenché l'événement : la capture elle-même, une
/// connexion directe, une diffusion vers un membre de Space, ou un cast DLNA.
enum ConnectionEventType { capture, direct, space, dlna }

/// Résultat observé de l'événement. Reflète uniquement ce que l'app sait
/// réellement (accepté/refusé par le récepteur, exception réseau, membre non
/// détecté) — jamais un état simulé.
enum ConnectionOutcome { started, stopped, connected, refused, offline, error }

/// Une ligne de l'historique local des connexions, persistée sur l'appareil
/// (voir [ConnectionHistoryService]). Ne contient que des informations
/// dérivées d'actions réelles de l'utilisateur ou de réponses réelles du
/// réseau.
class ConnectionEvent {
  const ConnectionEvent({
    required this.timestamp,
    required this.type,
    required this.target,
    required this.outcome,
  });

  final DateTime timestamp;
  final ConnectionEventType type;

  /// Nom du récepteur/Space/renderer concerné. Vide pour un événement de type
  /// [ConnectionEventType.capture], qui ne concerne pas une cible précise.
  final String target;
  final ConnectionOutcome outcome;

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'type': type.name,
    'target': target,
    'outcome': outcome.name,
  };

  factory ConnectionEvent.fromJson(Map<String, dynamic> json) =>
      ConnectionEvent(
        timestamp: DateTime.parse(json['timestamp'] as String),
        type: ConnectionEventType.values.byName(json['type'] as String),
        target: json['target'] as String,
        outcome: ConnectionOutcome.values.byName(json['outcome'] as String),
      );
}
