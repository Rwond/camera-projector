import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:swvertex_camera_projector/features/projection/dlna_service.dart';
import 'package:swvertex_camera_projector/features/projection/projection_screen.dart';

/// Pas de vraie découverte SSDP dans les tests : le réseau de la machine qui
/// exécute la suite n'a rien à voir là-dedans (voir discovery_registry_test.dart
/// pour le même principe côté Wi-Fi local).
class _NoRenderersDlnaService extends DlnaCastService {
  const _NoRenderersDlnaService();

  @override
  Future<List<DlnaRenderer>> discover({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    return const [];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(
    'com.swvertex.camera_projector/projection_test',
  );
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  testWidgets('affiche l\'état arrêté et le bouton de démarrage', (
    tester,
  ) async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'status') {
        return <String, dynamic>{'running': false};
      }
      return null;
    });

    await tester.pumpWidget(
      const MaterialApp(home: ProjectionScreen(isAndroidOverride: true, enableScanning: false)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Capture arrêtée'), findsOneWidget);
    expect(find.text('Démarrer la capture'), findsOneWidget);
  });

  testWidgets('affiche l\'URL quand la capture est active', (tester) async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'status') {
        return <String, dynamic>{
          'running': true,
          'ip': '192.168.1.10',
          'port': 8080,
          'url': 'http://192.168.1.10:8080/',
        };
      }
      return null;
    });

    await tester.pumpWidget(
      const MaterialApp(home: ProjectionScreen(isAndroidOverride: true, enableScanning: false)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Capture active'), findsOneWidget);
    expect(find.text('http://192.168.1.10:8080/'), findsOneWidget);
    expect(find.text('Arrêter la capture'), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('Copier l\'adresse'), findsOneWidget);
    expect(find.text('Partager le lien'), findsOneWidget);
  });

  testWidgets('le bouton démarre la capture puis affiche l\'adresse', (
    tester,
  ) async {
    var started = false;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'start') {
        started = true;
      }
      if (call.method == 'status' || call.method == 'start') {
        return started
            ? <String, dynamic>{
                'running': true,
                'ip': '192.168.1.10',
                'port': 8080,
                'url': 'http://192.168.1.10:8080/',
              }
            : <String, dynamic>{'running': false};
      }
      return null;
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: ProjectionScreen(
          isAndroidOverride: true,
          enableScanning: false,
          // Un Timer périodique réel (diagnostic en direct) entre en conflit
          // avec l'horloge virtuelle de pumpAndSettle hors de runAsync.
          enableLiveClock: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Démarrer la capture'));
    await tester.pumpAndSettle();

    expect(started, isTrue);
    expect(find.text('Capture active'), findsOneWidget);
    expect(find.text('http://192.168.1.10:8080/'), findsOneWidget);
  });

  group('contrôle à distance', () {
    testWidgets(
      'propose d\'activer le service d\'accessibilité tant qu\'il ne l\'est pas',
      (tester) async {
        messenger.setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'status':
              return <String, dynamic>{'running': false};
            case 'isAccessibilityServiceEnabled':
              return false;
            case 'isRemoteControlEnabled':
              return false;
          }
          return null;
        });

        tester.view.physicalSize = const Size(800, 2000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          const MaterialApp(
            home: ProjectionScreen(isAndroidOverride: true, enableScanning: false),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Activer le service d\'accessibilité'),
          findsOneWidget,
        );
        expect(find.byType(Switch), findsNothing);
      },
    );

    testWidgets('active/désactive le contrôle une fois le service actif', (
      tester,
    ) async {
      var remoteControlEnabled = false;
      messenger.setMockMethodCallHandler(channel, (call) async {
        switch (call.method) {
          case 'status':
            return <String, dynamic>{'running': false};
          case 'isAccessibilityServiceEnabled':
            return true;
          case 'isRemoteControlEnabled':
            return remoteControlEnabled;
          case 'setRemoteControlEnabled':
            remoteControlEnabled =
                (call.arguments as Map)['enabled'] as bool;
            return remoteControlEnabled;
        }
        return null;
      });

      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: ProjectionScreen(isAndroidOverride: true, enableScanning: false),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Contrôle à distance désactivé'), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(remoteControlEnabled, isTrue);
      expect(find.text('Contrôle à distance actif'), findsOneWidget);
    });
  });

  testWidgets(
    'la recherche DLNA se termine sans planter quand aucun récepteur ne répond',
    (tester) async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'status') {
          return <String, dynamic>{'running': false};
        }
        return null;
      });

      tester.view.physicalSize = const Size(800, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: ProjectionScreen(
            isAndroidOverride: true,
            enableScanning: false,
            dlnaService: _NoRenderersDlnaService(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rechercher des Smart TV'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Recherche en cours…'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );
}
