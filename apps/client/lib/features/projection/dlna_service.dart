import 'dart:io';

import 'package:upnp_client/upnp_client.dart';
import 'package:xml/xml.dart';

/// Un récepteur DLNA/UPnP détecté sur le réseau local (ex. une Smart TV).
/// Contrairement à la connexion directe (lib/features/projection/pairing_service.dart),
/// aucune app SWVERTEX n'est nécessaire sur cet appareil — mais il faut déjà
/// qu'il expose un service DLNA MediaRenderer, et rien ne garantit qu'il sache
/// lire le flux MJPEG du mode B (voir les limites documentées dans l'écran).
class DlnaRenderer {
  const DlnaRenderer({required this.name, required this.device});

  final String name;
  final MediaRenderer device;
}

/// Découvre les récepteurs DLNA du réseau et leur envoie l'adresse du flux
/// MJPEG du mode B. Prototype labo : la découverte UPnP/SSDP n'a pu être
/// vérifiée qu'en conditions de développement, jamais contre une vraie Smart
/// TV — voir STATUS.md.
class DlnaCastService {
  const DlnaCastService();

  Future<List<DlnaRenderer>> discover({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    final discoverer = DeviceDiscoverer();
    final found = <DlnaRenderer>[];
    try {
      await discoverer.start(addressTypes: [InternetAddressType.IPv4]);
      final devices = await discoverer.getDevices(
        searchTarget: UpnpDeviceType.mediaRenderer.urn(),
        timeout: timeout,
      );
      for (final device in devices.whereType<MediaRenderer>()) {
        // Sans AVTransport, le récepteur ne peut pas se voir confier une
        // adresse à lire : il ne sert à rien pour notre usage.
        if (device.avTransport == null) continue;
        found.add(
          DlnaRenderer(
            name: device.description?.friendlyName ?? 'Récepteur DLNA',
            device: device,
          ),
        );
      }
    } finally {
      discoverer.stop();
    }
    return found;
  }

  Future<void> cast(DlnaRenderer target, Uri streamUri) async {
    final transport = target.device.avTransport;
    if (transport == null) {
      throw StateError('Ce récepteur n\'expose pas AVTransport.');
    }
    await transport.setAVTransportURI(
      streamUri.toString(),
      metadata: _buildDidlMetadata(streamUri),
    );
    await transport.play();
  }

  String _buildDidlMetadata(Uri streamUri) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element(
      'DIDL-Lite',
      nest: () {
        builder.attribute(
          'xmlns',
          'urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/',
        );
        builder.attribute('xmlns:dc', 'http://purl.org/dc/elements/1.1/');
        builder.attribute(
          'xmlns:upnp',
          'urn:schemas-upnp-org:metadata-1-0/upnp/',
        );
        builder.element(
          'item',
          nest: () {
            builder.attribute('id', '0');
            builder.attribute('parentID', '-1');
            builder.attribute('restricted', '1');
            builder.element('dc:title', nest: 'Projection SWVERTEX');
            builder.element('upnp:class', nest: 'object.item.videoItem');
            builder.element(
              'res',
              nest: () {
                // Format MJPEG best-effort : rien ne garantit qu'un
                // récepteur DLNA donné l'accepte, voir les limites
                // documentées dans l'écran mode B.
                builder.attribute(
                  'protocolInfo',
                  'http-get:*:multipart/x-mixed-replace:*',
                );
                builder.text(streamUri.toString());
              },
            );
          },
        );
      },
    );
    return builder.buildDocument().toXmlString();
  }
}
