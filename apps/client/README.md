# apps/client — Application SWVERTEX CAMERA PROJECTOR (mobile + desktop/récepteur)

Projet Flutter unique multi-cible (Android, iOS, Windows, macOS, Web) — §4-5 du cahier des charges.
Pour l'instant : authentification réelle et gestion des appareils associés au compte, consommant
directement l'API du backend. Aucun module natif (capture caméra/écran, USB-C, découverte Wi-Fi)
n'est encore développé — voir STATUS.md.

## Démarrage

```bash
flutter pub get
flutter run -d windows   # ou -d chrome, -d <id-émulateur-android>, etc.
```

`API_URL` (par défaut `http://localhost:3001`) peut être surchargé à la compilation :

```bash
flutter run --dart-define=API_URL=http://10.0.2.2:3001   # émulateur Android -> hôte
flutter run --dart-define=API_URL=http://192.168.x.x:3001 # appareil physique -> IP LAN de la machine hôte
```

## Vérification Web dans le navigateur (CI/agent)

`flutter run -d chrome` ouvre son propre Chrome et attend une connexion de débogage websocket —
incompatible avec un navigateur piloté à distance (ex. l'outil de navigateur de cet agent). Pour
vérifier le rendu dans un navigateur externe :

```bash
flutter build web --dart-define=API_URL=http://localhost:3001
cd build/web && python -m http.server 3004
```

Puis ouvrir `http://localhost:3004`. Le port 3004 est déjà autorisé dans `CORS_ORIGINS` du backend.
**Ne pas réutiliser le même port pour un `flutter run` en mode debug puis un build statique** : le
service worker du premier peut rester en cache sur cette origine et servir du contenu périmé — en
cas de doute, changer de port ou vider le cache du site avant de retester.

## Prototype de projection (labo, Android)

Premier prototype du mode B : capture de l'écran Android via `MediaProjection`, encodage JPEG et
diffusion MJPEG sur le réseau local. Aucun backend ni matériel projecteur n'est nécessaire.

```bash
flutter build apk --debug --dart-define=LAB_MODE=true
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

`LAB_MODE=true` ouvre directement l'écran de test, sans authentification (uniquement en build
debug). Sans ce flag, l'écran reste accessible après connexion via le bouton
« Tester la projection (labo) » de l'accueil.

Utilisation :

1. Connecter le téléphone et le récepteur (PC/TV) au même réseau Wi-Fi.
2. Démarrer la capture et accepter la demande Android.
3. Ouvrir l'adresse affichée dans un navigateur sur le récepteur, par exemple
   `http://192.168.1.23:8080/`.

En USB uniquement : `adb reverse tcp:8080 tcp:8080`, puis ouvrir `http://localhost:8080/` sur le PC.

Limites : Android uniquement, sans son, environ 10 images/s en JPEG 720p. Ce n'est **pas** encore
le mode B final : Miracast/DLNA et le protocole des projecteurs Wi-Fi restent à définir
(`docs/decisions-a-valider.md`). Le code natif se trouve dans
`android/app/src/main/kotlin/com/swvertex/swvertex_camera_projector/ScreenStreamService.kt` et
l'écran Flutter dans `lib/features/projection/`.

## Stockage et sécurité

Les jetons d'accès/rafraîchissement sont stockés via `flutter_secure_storage` (Keychain/Keystore/
DPAPI selon la plateforme, WebCrypto sur Web) — jamais en clair dans `shared_preferences`.

## Architecture du code

```
lib/core/            Client HTTP (ApiClient) et stockage sécurisé des jetons (TokenStorage)
lib/features/auth/    Connexion, inscription, AuthService
lib/features/devices/ Liste/association/dissociation des appareils du compte
lib/features/home/    Écran d'accueil post-connexion
```

Tout ce qui est spécifique à l'OS (capture caméra/écran, USB-C, découverte réseau Wi-Fi) devra
passer par des canaux de plateforme (platform channels) derrière une interface Dart commune, pour
qu'une limitation d'une plateforme n'affecte jamais le contrat des autres (voir ARCHITECTURE.md).
