import 'package:screen_brightness/screen_brightness.dart';

/// Pousse la luminosité au maximum pendant la projection par lentille, puis la
/// restaure. La luminosité logicielle n'est qu'un confort : si la plateforme
/// ne l'expose pas (web, certains environnements desktop), les méthodes
/// échouent silencieusement et l'écran de projection reste utilisable.
class LensBrightnessService {
  const LensBrightnessService();

  Future<bool> maximize() async {
    try {
      await ScreenBrightness.instance.setApplicationScreenBrightness(1.0);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> restore() async {
    try {
      await ScreenBrightness.instance.resetApplicationScreenBrightness();
    } catch (_) {
      // Rien à restaurer sur une plateforme qui n'a pas pu passer en luminosité max.
    }
  }
}
