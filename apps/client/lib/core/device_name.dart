import 'dart:io';

/// Nom affiché à l'autre appareil pendant l'appairage direct (ex. « X
/// souhaite projeter sur cet écran »). `Platform.localHostname` n'existe pas
/// sur Web, mais la connexion directe (sockets bruts) n'y est de toute façon
/// pas disponible.
String defaultDeviceName() {
  try {
    final host = Platform.localHostname;
    return host.isNotEmpty ? host : 'Appareil SWVERTEX';
  } catch (_) {
    return 'Appareil SWVERTEX';
  }
}
