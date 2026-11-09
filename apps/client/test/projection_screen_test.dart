import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:swvertex_camera_projector/features/projection/projection_screen.dart';

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
      const MaterialApp(home: ProjectionScreen(isAndroidOverride: true, enableScanning: false)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Démarrer la capture'));
    await tester.pumpAndSettle();

    expect(started, isTrue);
    expect(find.text('Capture active'), findsOneWidget);
    expect(find.text('http://192.168.1.10:8080/'), findsOneWidget);
  });
}
