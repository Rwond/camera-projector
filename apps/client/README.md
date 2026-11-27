# apps/client — Application SWVERTEX CAMERA PROJECTOR (mobile + desktop/récepteur)

Projet Flutter unique multi-cible (Android, iOS, Windows, macOS, Web) — §4-5 du cahier des charges.
Pour l'instant : authentification réelle et gestion des appareils associés au compte, consommant
directement l'API du backend. Aucun module natif (capture caméra/écran, USB-C, découverte Wi-Fi)
n'est encore développé — voir STATUS.md.

## Navigation de l'accueil (connecté)

Une fois connecté, l'app affiche une coquille à 5 onglets (`lib/features/home/home_screen.dart`) :
Accueil, Spaces, Sources, Appareils, Réglages.

- **Accueil** : action principale (démarrer une projection Mode B) + accès rapide aux autres
  prototypes réels.
- **Spaces** : réel — un Space regroupe des récepteurs (PC/TV ayant déjà ouvert « Recevoir une
  projection ») pour diffuser vers tous en un geste. Voir la section dédiée plus bas.
- **Sources** : bibliothèque de types de source. « Écran » (Mode B), « Lentille » (Mode C),
  « Photos », « Vidéos », « Documents », « Présentations » et « Tableau blanc » (voir plus bas)
  sont cliquables ; seule « Caméra » apparaît encore grisée « À venir ».
- **Appareils** : écran existant (`devices_screen.dart`), inchangé fonctionnellement.
- **Réglages** : uniquement des réglages réels (déconnexion) — pas de bascule thème clair/sombre
  factice, l'app reste volontairement sombre uniquement (voir `theme/app_theme.dart`).

Typographie : Space Grotesk (titres) + Inter (corps de texte), via le paquet `google_fonts`
(polices embarquées, mises en cache localement après le premier lancement — aucune dépendance
réseau au runtime une fois le cache rempli).

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

### Connexion directe (sans navigateur)

Alternative à l'étape 3 ci-dessus : si le récepteur (PC/TV) exécute aussi cette application, ouvre
« Recevoir une projection (labo) » depuis son accueil — il devient visible sur le réseau local sous
le nom de sa machine. Depuis le téléphone, une fois la capture démarrée, la carte « Connexion
directe » de l'écran mode B liste les récepteurs détectés : toucher « Se connecter » envoie une
demande d'autorisation ; le récepteur affiche « *X* souhaite projeter sur cet écran. Accepter ? » et,
en cas d'acceptation, affiche le flux directement dans l'application (pas de navigateur, pas d'URL à
recopier).

Fonctionnement : découverte par diffusion UDP (`lib/features/projection/discovery_service.dart`,
port 45680), demande/réponse JSON sur TCP (`pairing_service.dart`), puis lecture du flux
`multipart/x-mixed-replace` directement en Dart (`core/mjpeg_client.dart`, sans `<img>` de
navigateur) et affichage (`mjpeg_viewer_screen.dart`).

Limites, honnêtement : **Wi-Fi local uniquement**. Ni Bluetooth ni câble USB ne sont implémentés —
chacun demanderait un module natif par plateforme (API Bluetooth Classic très différentes entre
Android/Windows/macOS, mode accessoire USB côté hôte...), un chantier à part entière non entamé ici
et de toute façon dépendant des décisions encore ouvertes dans `docs/decisions-a-valider.md`.

Vérifié pour de vrai entre un téléphone Android et un PC Windows sur le même réseau Wi-Fi :
découverte, demande d'autorisation et affichage du flux sans navigateur fonctionnent bout en bout.

### Spaces : diffuser vers plusieurs récepteurs enregistrés

Onglet « Spaces » de l'accueil (`lib/features/home/spaces_tab.dart`,
`lib/features/spaces/`) : un Space est un groupe nommé de récepteurs, construit entièrement
sur la connexion directe ci-dessus — **pas** une session serveur partagée, purement local à
cet appareil (persisté via `shared_preferences`, survit aux relances de l'app).

Utilisation :

1. Depuis l'onglet Spaces, les récepteurs détectés sur le réseau (même mécanisme de découverte
   UDP que la connexion directe) peuvent être ajoutés à un Space nouveau ou existant.
2. Depuis l'écran mode B, une fois la capture démarrée, la section « Spaces » liste les Spaces
   créés avec un bouton « Diffuser » : envoie une demande de connexion à chaque membre
   actuellement détecté sur le réseau, séquentiellement, et affiche le résultat par membre
   (connecté/refusé/hors ligne/échec).

Rapprochement honnête, pas magique : un membre est identifié par **nom d'appareil** (stable),
pas par adresse/port (qui changent à chaque relance de l'écran récepteur — port TCP éphémère,
adresse DHCP). Un membre enregistré mais non détecté sur le réseau au moment de diffuser est
affiché « hors ligne », jamais simulé comme connecté. Spaces hérite donc exactement des mêmes
limites que la connexion directe (Wi-Fi local uniquement, pas de confirmation automatique côté
récepteur).

### Contrôle de session enrichi (historique local, arrêt confirmé, diagnostic)

Sur l'écran mode B (`lib/features/projection/projection_screen.dart`,
`connection_history.dart`/`connection_history_service.dart`) :

- **Historique des connexions** : journal local (persisté via `shared_preferences`, comme
  Spaces — jamais synchronisé) des démarrages/arrêts de capture et des tentatives de connexion
  directe, Space ou Smart TV, avec résultat (connecté/refusé/hors ligne/échec) et horodatage.
  Les 10 événements les plus récents sont affichés, 50 au total sont conservés ; un bouton
  « Effacer » vide le journal.
- **Diagnostic en direct** : pendant que la capture tourne, affiche l'adresse réseau, la durée
  de capture (uniquement si démarrée depuis cet écran — sinon affiché honnêtement comme
  « durée inconnue » plutôt que d'inventer une heure de départ), le nombre de connexions
  actives (directe + Spaces + DLNA) et le dernier événement de l'historique.
- **Arrêt confirmé** : si une connexion directe, un membre de Space ou un cast DLNA est
  actif au moment d'arrêter la capture, une boîte de dialogue demande confirmation (l'arrêt
  coupe ces connexions) avant d'agir ; sans connexion active, l'arrêt reste immédiat comme
  avant.

Honnêteté : comme pour Spaces, rien n'est synchronisé ni mesuré au-delà de ce que l'app sait
réellement — pas de débit image ni de qualité réseau, qui ne sont pas mesurés ici.

### QR code et partage du lien

Sur l'écran mode B classique (navigateur), la capture affiche en plus un QR code encodant l'adresse
et un bouton « Partager le lien » qui ouvre le menu de partage natif (Bluetooth, messagerie, e-mail,
selon ce que le destinataire accepte) — pour ne pas avoir à recopier l'adresse à la main. Le
Bluetooth sert ici uniquement à transmettre le **texte de l'adresse**, pas le flux vidéo lui-même
(voir plus bas pourquoi diffuser la vidéo elle-même par Bluetooth n'est pas réaliste).

### Contrôle à distance (expérimental, labo)

Depuis la page du navigateur servie par le mode B classique, un clic sur l'image rejoue un appui à
l'endroit correspondant sur l'écran du téléphone (`RemoteControlAccessibilityService.kt`, API
Android `AccessibilityService.dispatchGesture`, publique depuis Android 7).

**Implication de sécurité à connaître avant d'activer cette fonction** : tant que le contrôle à
distance est activé dans l'app, **n'importe qui atteignant l'adresse du flux sur le réseau local
peut contrôler l'écran du téléphone** — il n'y a pas de confirmation par appui, contrairement à la
connexion directe. Deux garde-fous : (1) le service d'accessibilité doit être activé manuellement
par l'utilisateur dans Réglages Android (l'app ne peut pas le faire à sa place), et (2) le contrôle
est désactivé par défaut et à chaque fermeture de l'écran — à n'activer que sur un réseau de
confiance, et à désactiver juste après usage.

Limites : un seul tap à la fois (pas de glissement ni de clavier), précision dépendant du calcul
(fait côté navigateur) de la zone réellement occupée par l'image dans sa boîte d'affichage. Pas de
harnais de test instrumenté Android dans cet environnement : la partie native n'a pas pu être
vérifiée sur un vrai geste, seule la partie Dart (bascule, avertissement, appels de canal) est
testée.

### Smart TV (DLNA, prototype séparé)

Section « Smart TV (DLNA) » du même écran : découvre les récepteurs DLNA/UPnP du réseau
(`lib/features/projection/dlna_service.dart`, bibliothèque `upnp_client`) et leur envoie l'adresse du
flux via `SetAVTransportURI` + `Play`. Contrairement à la connexion directe, **aucune app SWVERTEX
n'est nécessaire sur la TV** — mais contrairement aussi à la connexion directe, **la TV ne demande
aucune confirmation** : elle essaie simplement de lire l'adresse envoyée.

**Compatibilité non garantie, honnêtement** : le flux envoyé est le MJPEG brut du mode B
(`multipart/x-mixed-replace`), alors que la plupart des récepteurs DLNA grand public attendent un
format vidéo standard (MP4/H.264) avec une taille de fichier connue. Rien ne garantit qu'un
téléviseur donné accepte ou affiche correctement ce flux — jamais vérifié contre une vraie Smart TV
dans cet environnement, qui n'en possède aucune.

### Ce qui reste délibérément hors de portée

- **Miracast** (diffusion d'écran native vers un PC/TV sans rien y installer) : bloqué par Android
  lui-même, pas par un manque de temps. L'API de diffusion Wi-Fi Display est protégée par la
  permission système `CONFIGURE_WIFI_DISPLAY`, réservée aux apps signées avec la clé de l'OS —
  aucune app tierce, y compris la nôtre, ne peut l'utiliser.
- **Diffuser la vidéo elle-même par Bluetooth** : demanderait un module natif par plateforme (API
  Bluetooth Classic très différentes entre Android/Windows/macOS), un chantier à part entière non
  entamé ici.
- **Caster vers un appareil quelconque sans rien y installer ni navigateur ouvert** (ex. un autre
  téléphone nu) : n'existe pas avec les technologies actuelles — il faut toujours soit un navigateur,
  soit l'app installée, soit (DLNA) un appareil qui expose déjà nativement un lecteur compatible.

## Prototype de projection (labo, lentille optique)

Second prototype, multiplateforme cette fois : affiche une image choisie (ou un motif
de calibrage à défaut) en plein écran, orientée selon le montage optique de
l'accessoire, et pousse la luminosité au maximum quand la plateforme le permet.
Aucun matériel requis pour le tester (le téléphone n'est pas nécessaire) — accessible
depuis l'accueil via « Projection par lentille (prototype) ».

Limites : la lentille elle-même (boîtier, distance focale) n'est ni fournie ni
spécifiée par ce projet (voir `docs/decisions-a-valider.md`) ; l'orientation
(aucun/horizontal/vertical/180°) est donc réglable manuellement en attendant un choix
d'accessoire définitif. La luminosité logicielle maximale n'est pas disponible sur
toutes les plateformes (ex. web) : l'écran reste utilisable sans elle.

## Source « Photos »

Onglet Sources → « Photos » (`lib/features/photos/photo_viewer_screen.dart`) : choisit une
photo du téléphone (`file_picker`) et l'affiche en plein écran. **Ne diffuse rien par
elle-même** — c'est un visionneur, pas un module de streaming. Pour projeter la photo
affichée sur un autre appareil, combiner avec le Mode B (capture d'écran) ou Smart TV (DLNA)
déjà réels : ces derniers capturent/diffusent ce qui est à l'écran, quel que soit son contenu,
donc fonctionnent aussi bien avec cette visionneuse qu'avec n'importe quel autre écran.

## Source « Vidéos »

Onglet Sources → « Vidéos » (`lib/features/videos/video_viewer_screen.dart`, bibliothèque
`video_player`) : choisit un fichier vidéo et le lit en plein écran, avec lecture/pause.
**Ne diffuse rien par elle-même** — comme Photos, à combiner avec le Mode B ou Smart TV (DLNA)
pour projeter ailleurs ce qui est lu ici.

Limites, honnêtement :

- **Non disponible sur le Web dans ce prototype** : `video_player` y a besoin d'une URL
  (réseau ou blob), pas d'un chemin de fichier local — construire l'URL blob nécessaire n'a
  pas été fait ici. Un message explicite s'affiche plutôt que d'échouer silencieusement.
- **L'échec d'initialisation du lecteur est affiché honnêtement** (message d'erreur, pas de
  blocage) plutôt que de laisser un indicateur de chargement tourner indéfiniment — un délai
  de garde de 8 s couvre le cas où la plateforme ne signale pas clairement l'échec.
- **Jamais vérifié avec un vrai fichier vidéo sur un appareil physique** dans cet
  environnement (pas de téléphone/PC disponible pendant cette session) — seul le
  comportement face à un échec d'initialisation (chemin absent, plateforme non implémentée)
  est couvert par les tests automatisés.

## Source « Documents »

Onglet Sources → « Documents » (`lib/features/documents/document_viewer_screen.dart`) :
choisit un fichier et l'affiche en plein écran **uniquement s'il s'agit de texte brut**
(`.txt`, `.md`, `.csv`, `.log`, `.json`). Pour tout autre format (PDF, Word, PowerPoint...),
affiche un message honnête plutôt qu'un faux rendu — construire un moteur de rendu par format
est un chantier à part entière, non entamé ici. Ne diffuse rien par elle-même, mêmes
combinaisons que Photos/Vidéos pour projeter ailleurs.

## Source « Présentations »

Onglet Sources → « Présentations » (`lib/features/presentations/presentation_viewer_screen.dart`) :
choisit une série d'images (sélection multiple) et les affiche comme un diaporama plein écran,
navigable diapositive par diapositive (boutons précédent/suivant, compteur « X / N »). Choisir
à nouveau remplace entièrement le diaporama en cours — pas d'ajout/suppression ciblée dans ce
prototype.

Honnêteté : **ne lit pas les fichiers `.pptx`/`.key`/`.odp` eux-mêmes** — aucun moteur de rendu
de présentation n'est construit ici (chantier à part entière). Pour projeter une présentation
existante, l'exporter en images (une par diapositive) depuis l'application d'origine, puis
choisir ces images ici. Ne diffuse rien par elle-même, mêmes combinaisons que Photos/Vidéos/
Documents (Mode B ou Smart TV DLNA) pour projeter ailleurs.

## Source « Tableau blanc »

Onglet Sources → « Tableau blanc » (`lib/features/whiteboard/whiteboard_screen.dart`) :
surface de dessin libre au doigt/souris, 5 couleurs et 3 épaisseurs de trait, annuler le
dernier trait, tout effacer (avec confirmation — destructif). Rendu via `CustomPainter` pur
Dart, sans dépendance native : fonctionne y compris sur le Web.

Honnêteté : **le dessin n'est pas enregistré** — il est perdu en quittant cet écran (pas de
sauvegarde, pas d'export image dans ce prototype). Ne diffuse rien par elle-même, mêmes
combinaisons que les autres sources (Mode B ou Smart TV DLNA) pour projeter ailleurs.

## Stockage et sécurité

Les jetons d'accès/rafraîchissement sont stockés via `flutter_secure_storage` (Keychain/Keystore/
DPAPI selon la plateforme, WebCrypto sur Web) — jamais en clair dans `shared_preferences`.

## Architecture du code

```
lib/core/              Client HTTP, stockage sécurisé des jetons, client MJPEG, nom d'appareil
lib/features/auth/      Connexion, inscription, AuthService
lib/features/devices/   Liste/association/dissociation des appareils du compte
lib/features/home/      Écran d'accueil post-connexion
lib/features/lens/      Prototype du mode C (lentille) : affichage plein écran + luminosité
lib/features/projection/ Prototype mode B + connexion directe (découverte, appairage, visionneuse)
lib/theme/              Palette de marque (extraite du logo) et thème Material 3
```

Tout ce qui est spécifique à l'OS (capture caméra/écran, USB-C, découverte réseau Wi-Fi) devra
passer par des canaux de plateforme (platform channels) derrière une interface Dart commune, pour
qu'une limitation d'une plateforme n'affecte jamais le contrat des autres (voir ARCHITECTURE.md).
