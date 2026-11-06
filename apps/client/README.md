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
