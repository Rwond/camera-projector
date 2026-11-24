import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

/// Exécuté avant chaque fichier de test : évite que les écrans qui lisent
/// SharedPreferences (Spaces) ne tentent de parler à un vrai canal de
/// plateforme absent en test, sans devoir répéter ce mock dans chaque
/// fichier.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  SharedPreferences.setMockInitialValues({});
  await testMain();
}
