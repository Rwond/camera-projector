/// Un appareil récepteur enregistré dans un [Space] : la dernière adresse/port
/// connus, pas une garantie de disponibilité — voir [SpaceMember.key] pour le
/// rapprochement avec un [DiscoveredReceiver] vu sur le réseau au moment de
/// diffuser.
class SpaceMember {
  const SpaceMember({required this.name, required this.lastAddress, required this.lastPairPort});

  factory SpaceMember.fromJson(Map<String, dynamic> json) {
    return SpaceMember(
      name: json['name'] as String,
      lastAddress: json['lastAddress'] as String,
      lastPairPort: json['lastPairPort'] as int,
    );
  }

  final String name;
  final String lastAddress;
  final int lastPairPort;

  /// Identifiant de rapprochement avec un `DiscoveredReceiver` vu sur le
  /// réseau : volontairement basé sur le **nom** de l'appareil, pas sur
  /// adresse:port. Ces derniers changent à chaque relance de l'écran
  /// récepteur (port TCP éphémère, adresse DHCP) — seul le nom reste stable
  /// d'une session à l'autre, voir `defaultDeviceName()`.
  String get key => name.trim().toLowerCase();

  Map<String, dynamic> toJson() => {
    'name': name,
    'lastAddress': lastAddress,
    'lastPairPort': lastPairPort,
  };

  @override
  bool operator ==(Object other) =>
      other is SpaceMember &&
      other.name == name &&
      other.lastAddress == lastAddress &&
      other.lastPairPort == lastPairPort;

  @override
  int get hashCode => Object.hash(name, lastAddress, lastPairPort);
}

/// Un Space : un groupe nommé de récepteurs vers lesquels diffuser en un seul
/// geste, construit sur la connexion directe existante (découverte UDP +
/// appairage TCP). Ce n'est pas une session serveur partagée — purement local
/// à cet appareil, persistant d'une session de l'app à l'autre.
class Space {
  const Space({required this.id, required this.name, required this.members});

  factory Space.fromJson(Map<String, dynamic> json) {
    return Space(
      id: json['id'] as String,
      name: json['name'] as String,
      members: (json['members'] as List<dynamic>)
          .map((m) => SpaceMember.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }

  final String id;
  final String name;
  final List<SpaceMember> members;

  Space copyWith({String? name, List<SpaceMember>? members}) {
    return Space(id: id, name: name ?? this.name, members: members ?? this.members);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'members': members.map((m) => m.toJson()).toList(),
  };
}
