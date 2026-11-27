# État d'avancement — SWVERTEX CAMERA PROJECTOR

Convention : une ligne passe en **Terminé** seulement si elle est implémentée ET testée (automatiquement ou manuellement, avec preuve). "Scaffold" = structure posée, aucune logique métier encore écrite.

Dernière mise à jour : 2026-11-27 (sources Vidéos et Documents).

## Terminé

- Socle monorepo : structure de dossiers, **vrai workspace npm** (hoisting à la racine — les commandes
  backend s'exécutent avec `npm run <script> --workspace=services/backend` depuis la racine, pas
  `cd services/backend && npm run ...`), Docker Compose (Postgres 17 + Redis 7), `.gitignore`, CI GitHub
  Actions pour le backend (`.github/workflows/backend-ci.yml`).
- Backend NestJS scaffoldé, compile (`npm run build --workspace=services/backend`) et démarre.
- Schéma Prisma initial (§12 du cahier des charges) : migration `init` créée et appliquée sur la base
  de développement.
- Module `health` : `GET /health` (liveness) et `GET /health/db` (ping base de données réelle).
- Module `users` : `UsersService` (recherche par e-mail/id, création).
- Module `auth` : `POST /auth/register` et `POST /auth/login`, hash bcrypt, émission de JWT
  access/refresh, `JwtAuthGuard` réutilisable (vérifie le header `Authorization: Bearer`, attache
  l'utilisateur à la requête).
- Module `organizations` (§6.2) : création d'organisation (créateur = OWNER), invitation d'un membre
  existant par e-mail, acceptation d'invitation, retrait d'un membre (le OWNER ne peut pas être retiré),
  liste des membres — autorisations vérifiées côté serveur (OWNER/ADMIN uniquement pour inviter/retirer).
- Module `devices` (§6.3, hors accessoires/compatibilité) : enregistrement d'un appareil (type,
  plateforme, modèle, OS, version d'app), liste des appareils du compte, heartbeat (`lastActiveAt`),
  révocation (dissociation) — accès strictement limité au propriétaire, vérifié côté serveur.
- Module `accessories` (§6.3, partie accessoires) : un utilisateur peut associer ("claim") un
  accessoire déjà enregistré au catalogue par son numéro de série, le lister, le dissocier
  ("release") ; accès strictement limité au propriétaire. La création de fiches catalogue est
  désormais exposée en `POST /admin/accessories`, protégée par le RBAC admin.
- Module `compatibility` (§7.5/§9.2) : lecture publique (sans authentification) de la matrice de
  compatibilité avec filtres par modèle d'appareil, d'accessoire et mode de projection — alimente la
  future page "Compatibilité" du site public. L'écriture est exposée en `POST /admin/compatibility`,
  protégée par le RBAC admin.
- **RBAC admin (§8)** : matrice de permissions statique pour les 7 rôles du cahier des charges
  (`services/backend/src/rbac/permissions.ts`), `AdminPermissionGuard` (relit le rôle en base à
  chaque requête, ne fait jamais confiance à un rôle mis en cache dans le jeton), décorateur
  `@RequirePermission(resource, action)`, `AuditService` qui journalise chaque action sensible dans
  `AuditLog`. Endpoints : `PATCH /admin/users/:id/admin-role` (seul SUPER_ADMIN peut accorder/retirer
  un rôle — encodé dans la matrice, pas en dur), `GET /admin/audit-log`. Le tout premier Super Admin
  doit être promu hors API (écriture DB directe/script d'exploitation) — documenté comme limitation
  volontaire, pas de voie d'auto-promotion exposée.
- Module `cms` (§9) : pages et articles (actualités/guides/FAQ) avec cycle de vie complet
  brouillon→publication→dépublication, ou brouillon→programmation (`schedule`, avec validation que la
  date est dans le futur)→publication manuelle au moment voulu. Lecture publique sans authentification
  (`GET /cms/pages`, `GET /cms/articles` avec filtre par catégorie) limitée au contenu réellement
  `PUBLISHED`. Écriture réservée au RBAC (ressource `cms`, rôle `CONTENT_MANAGER` ou `SUPER_ADMIN`),
  chaque action sensible journalisée dans `AuditLog`. Catalogue de médias (métadonnées uniquement :
  nom, URL, type MIME, taille — **l'upload de fichier lui-même n'est pas intégré**, `url` doit déjà
  pointer vers un fichier accessible ; pas de pipeline de stockage/CDN branché).
- Module `support` (§6.6) : création de ticket (catégorie + premier message), liste et consultation
  de ses propres tickets, réponse — un ticket `CLOSED` refuse les nouveaux messages du demandeur
  (400). Côté staff (RBAC, ressource `support`, rôle `SUPPORT_AGENT`/`SUPER_ADMIN`) : liste et
  consultation de tous les tickets (filtrables par statut/catégorie), ajout de messages publics ou de
  **notes internes jamais visibles du demandeur**, mise à jour du statut/priorité/assignation
  (journalisée dans `AuditLog`).
- Module `notifications` (§6.5) : journal d'envoi (`Notification` : canal, template, statut,
  tentatives, erreur), historique personnel (`GET /notifications`), vue admin complète et nouvelle
  tentative contrôlée (`POST /admin/notifications/:id/retry`). **Aucun fournisseur e-mail/push réel
  n'est branché** — le transport par défaut (`LogNotificationTransport`) se contente de journaliser et
  simule toujours un succès ; à remplacer par un vrai transport (SMTP/SendGrid/FCM, choix de
  prestataire en attente) sans changer le service, qui dépend d'une interface. Pas de déclenchement
  automatique depuis l'inscription pour éviter une dépendance circulaire avec `AuthModule` — déclenché
  pour l'instant uniquement via l'API admin (`POST /admin/notifications`, réservé à `SUPER_ADMIN`).
- 89 tests automatisés passants ; lint (`oxlint`) sans erreur ; vérifié manuellement en conditions
  réelles (serveur démarré, base de données de développement) : flux organizations complet
  (register→create org→invite→accept→list→retrait du owner refusé en 403→accès sans jeton refusé en
  401), flux devices complet (register→list→heartbeat→accès par un autre utilisateur refusé en 403→
  revoke→heartbeat après revoke refusé en 403→appareil inconnu en 404), flux accessories/compatibility
  (lecture publique de la compatibilité→claim d'un accessoire catalogué→double claim refusé en 409→
  numéro de série inconnu en 404→release par un autre utilisateur refusé en 403→release par le
  propriétaire→accès sans jeton refusé en 401), flux RBAC complet (utilisateur non promu refusé en
  403→promotion au premier Super Admin par écriture DB directe→Super Admin délègue TECHNICAL_OPERATOR
  à un autre compte→cet opérateur crée une fiche accessoire et un enregistrement de compatibilité→un
  utilisateur sans rôle est refusé en 403 sur les mêmes actions→le journal d'audit contient bien les
  trois actions effectuées), flux CMS complet (délégation CONTENT_MANAGER→création de page en
  brouillon invisible du public en 404→publication→visible du public en 200→un rôle sans permission
  cms refusé en 403→articles publiés filtrables par catégorie→dépublication d'un article disparaît
  bien de la liste publique→programmation future acceptée, programmation passée refusée en 400, page
  programmée toujours invisible du public→enregistrement d'un média), et flux support/notifications
  complet (délégation SUPPORT_AGENT→création de ticket→note interne de l'agent invisible pour le
  client (2 messages vus contre 3 côté staff)→un utilisateur sans rôle support refusé en 403→fermeture
  du ticket→nouveau message du client refusé en 400→notification envoyée par un Super Admin, visible
  dans l'historique du client et la vue admin, relance réussie→un support agent sans permission
  d'envoi refusé en 403).
- **Site public (`apps/site`, Next.js/App Router)** : accueil (page CMS `accueil`), compatibilité
  (`/compatibilite`, lit `GET /compatibility`), actualités (`/actualites`, catégorie `NEWS`), guides
  et FAQ (`/guides`, catégories `GUIDE`/`FAQ`), et une route générique `/[slug]` pour toute autre page
  CMS publiée — tout le contenu vient réellement du backend, rien n'est codé en dur. Rendu de blocs
  (`heading`, `text`, `cta`, `image`) via `BlockRenderer`, convention de contenu `{ blocks: Block[] }`
  documentée dans `apps/site/README.md`. CORS activé côté backend (`CORS_ORIGINS`, restreint à
  l'origine du site). Build (`next build`) et lint passent ; vérifié visuellement dans le navigateur
  sur les quatre pages plus un cas 404 réel sur une page inexistante.
- **Admin (`apps/admin`, Next.js/App Router)** : authentification par formulaire (`/login`) qui
  pose le jeton d'accès/rafraîchissement en cookies **httpOnly** (jamais exposés au JavaScript
  client — tous les appels au backend se font côté serveur Next.js, dans des Server
  Components/Actions, jamais depuis le navigateur ; aucun CORS nécessaire pour cette app).
  `proxy.ts` (ex-`middleware.ts` — convention renommée dans cette version de Next) redirige vers
  `/login` toute route protégée sans jeton. Tableau de bord affichant l'utilisateur connecté, page
  `/audit-log` consommant `GET /admin/audit-log` et affichant un message de refus propre (pas de
  crash) quand le rôle ne donne pas la permission. Déconnexion qui efface les cookies. Build et lint
  passent ; vérifié dans le navigateur : connexion, redirection si non connecté, affichage réel du
  journal d'audit, refus RBAC propre pour un compte sans rôle, déconnexion puis re-redirection.
- **Admin — Support (§6.6)** : liste des tickets (`/support`), détail avec tous les messages y
  compris les notes internes (mises en évidence visuellement, jamais envoyées au demandeur côté
  public), formulaire de réponse/note interne et mise à jour du statut/priorité, via Server Actions
  (`revalidatePath` après chaque mutation). Vérifié dans le navigateur avec un compte `SUPPORT_AGENT`
  réel : liste, détail, changement de statut confirmé côté backend, ajout d'un message visible
  immédiatement après soumission.
- **Admin — CMS (§9)** : `/cms/pages` et `/cms/articles` (liste, création, édition, publier/
  dépublier/programmer/supprimer) partagent un composant `BlockEditor` réutilisable (titre, texte,
  appel à l'action, image — ajout/suppression/réordonnancement de blocs, sérialisés en JSON dans un
  champ caché de formulaire). `/cms/media` : catalogue de métadonnées (enregistrement, suppression).
  Vérifié dans le navigateur avec un compte `CONTENT_MANAGER` réel : l'éditeur charge le contenu
  existant d'une page déjà publiée, un bloc ajouté et enregistré est bien persisté côté backend et
  immédiatement visible via la lecture publique (`GET /cms/pages/fr/accueil`), création d'un article
  en brouillon, enregistrement/suppression d'un média, refus RBAC propre pour un rôle sans accès CMS
  (`TECHNICAL_OPERATOR`).
- **Admin — Comptes/rôles, Accessoires, Compatibilité** : deux endpoints backend ajoutés pour
  rendre ces écrans possibles — `GET /admin/users` (recherche par e-mail, ressource `users:read`,
  ne renvoie jamais `passwordHash`) et `GET /admin/accessories` (catalogue complet, ressource
  `accessories:read`) ; `/compatibility` lit directement l'endpoint public existant (pas de
  changement backend nécessaire). `/users` : recherche + formulaire d'attribution de rôle par
  compte (la mise à jour elle-même reste réservée à `SUPER_ADMIN` par la matrice RBAC).
  `/accessories` : liste + création de fiche catalogue. `/compatibility` : liste + publication
  d'un résultat. Vérifié dans le navigateur avec des comptes réels : `/users` refusé pour
  `TECHNICAL_OPERATOR` (403 propre) mais `/accessories`/`/compatibility` fonctionnent pour ce
  rôle ; changement de rôle par un `SUPER_ADMIN` confirmé côté backend puis restauré à sa valeur
  d'origine ; nouvelle fiche accessoire et nouveau résultat de compatibilité visibles
  immédiatement après création.
- **Client Flutter (`apps/client`)** : projet unique multi-cible (Android/iOS/Windows/macOS/Web,
  §4-5 du cahier des charges) scaffoldé. Authentification réelle (connexion/inscription, jetons
  stockés via `flutter_secure_storage` — Keychain/Keystore/DPAPI/WebCrypto selon la plateforme,
  jamais en clair) et écran "Mes appareils" (liste, association via un formulaire, dissociation),
  consommant directement l'API du backend (`ApiClient` générique, pas de mock). `flutter analyze`
  et `flutter test` passent. Vérifié dans un vrai navigateur (build `flutter build web` servi
  statiquement — `flutter run -d chrome` attend une connexion de débogage websocket incompatible
  avec un navigateur piloté à distance, documenté dans `apps/client/README.md`) : inscription,
  doublon d'e-mail refusé avec le bon message, connexion, liste d'appareils vide puis peuplée après
  association réelle (confirmée côté backend), dissociation reflétée immédiatement, déconnexion.
  Aucun module natif (capture caméra/écran, USB-C, découverte Wi-Fi) n'est encore développé — ce
  sera le prochain chantier matériel/logiciel, derrière des canaux de plateforme par OS.

## En cours

- **Prototype de projection labo (Android, mode B)** : capture d'écran via `MediaProjection` +
  serveur MJPEG local, écran Flutter « Tester la projection (labo) » et mode `LAB_MODE=true` pour
  tester sans backend. Compilé (`flutter build apk --debug`), `flutter analyze` et `flutter test`
  passent. **Testé pour de vrai sur un téléphone physique (modèle Z2453, Android, armeabi-v7a)** :
  capture démarrée et autorisation Android acceptée avec succès. Ce prototype ne remplace pas le
  mode B final (Miracast/DLNA non implémentés).
- **Prototype de projection par lentille (mode C, multiplateforme)** : écran « Projection par
  lentille (prototype) » — affiche une image choisie ou un motif de calibrage en plein écran, avec
  4 orientations (aucun/horizontal/vertical/180°) en attendant le choix définitif du montage
  optique, et pousse la luminosité au maximum via `screen_brightness` quand la plateforme le
  permet. Ne nécessite aucun matériel ni le téléphone de test pour être vérifié. `flutter analyze`
  et `flutter test` passent.
- **Connexion directe mode B (sans navigateur)** : le téléphone découvre les récepteurs
  (PC/TV exécutant aussi l'app) par diffusion UDP sur le réseau local, envoie une demande
  d'autorisation TCP (JSON), et — si acceptée — le récepteur affiche le flux directement dans
  l'application (parsing `multipart/x-mixed-replace` en Dart pur, sans `<img>` de navigateur).
  Écrans « Recevoir une projection (labo) » (récepteur) et section « Connexion directe » de l'écran
  mode B (émetteur). `flutter analyze` et `flutter test` passent, y compris des tests d'intégration
  avec de vraies sockets en boucle locale (découverte, appairage accepter/refuser/expiration,
  parsing MJPEG, bout en bout écran récepteur). **Vérifié pour de vrai entre deux appareils
  physiques séparés** (téléphone Android ↔ PC Windows sur le même Wi-Fi) : découverte, demande
  d'autorisation et affichage du flux sans navigateur confirmés bout en bout. **Wi-Fi local
  uniquement** : ni Bluetooth ni câble USB ne sont implémentés (chacun demanderait un module natif
  par plateforme, non construit ici).
- **Spaces (groupes de récepteurs, client Flutter)** : un Space regroupe des récepteurs
  enregistrés (découverts puis ajoutés depuis l'onglet « Spaces ») pour diffuser vers tous en un
  geste depuis l'écran mode B (`lib/features/spaces/`, `lib/features/home/spaces_tab.dart`).
  Persisté localement (`shared_preferences`), construit entièrement sur la connexion directe
  déjà réelle — pas de session serveur partagée. Rapprochement par nom d'appareil (stable),
  jamais par adresse/port (éphémères) ; un membre non détecté au moment de diffuser est marqué
  « hors ligne », jamais simulé comme connecté. `flutter analyze`/`flutter test` passent,
  y compris des tests de bout en bout avec de vraies sockets en boucle locale (création/
  renommage/suppression d'un Space, ajout/retrait d'un membre, diffusion vers un membre en ligne
  et un membre hors ligne simultanément). **Vérifié visuellement dans le navigateur**
  (`flutter build web --debug`) : états vides honnêtes (aucun récepteur détecté, aucun Space
  créé), création d'un Space depuis la boîte de dialogue. Mêmes limites que la connexion
  directe : Wi-Fi local uniquement, pas de confirmation automatique côté récepteur.
- **Source « Photos » (client Flutter)** : choisit une photo du téléphone (`file_picker`) et
  l'affiche en plein écran (`lib/features/photos/photo_viewer_screen.dart`), accessible depuis
  l'onglet Sources. Ne diffuse rien par elle-même — à combiner avec le Mode B (capture d'écran)
  ou Smart TV (DLNA), déjà réels, pour projeter ce qui est affiché sur un autre appareil.
  `flutter analyze`/`flutter test` passent (choix d'image, activation du plein écran, fermeture
  au toucher). Vérifié visuellement dans le navigateur.
- **Sources « Vidéos » et « Documents » (client Flutter)** : `lib/features/videos/
  video_viewer_screen.dart` (bibliothèque `video_player`) choisit un fichier vidéo et le lit
  en plein écran (lecture/pause) ; **non disponible sur le Web** dans ce prototype
  (`video_player` y a besoin d'une URL, pas d'un chemin de fichier — message honnête affiché
  plutôt qu'un échec silencieux) et **jamais vérifié avec un vrai fichier sur un appareil
  physique** dans cet environnement (pas de téléphone/PC disponible pendant cette session).
  `lib/features/documents/document_viewer_screen.dart` choisit un fichier et l'affiche en
  plein écran s'il s'agit de texte brut (`.txt`/`.md`/`.csv`/`.log`/`.json`) ; tout autre
  format (PDF, Word, PowerPoint...) affiche un message honnête plutôt qu'un faux rendu — un
  moteur de rendu par format n'a pas été construit. `flutter analyze`/`flutter test`
  passent (56 tests), y compris l'échec réel d'initialisation du lecteur vidéo dans cet
  environnement de test (pas de double simulé — l'erreur de plateforme se produit
  réellement et l'état honnête qui en résulte est vérifié). Vérifié visuellement dans le
  navigateur : Documents fonctionne de bout en bout (texte affiché, plein écran), Vidéos
  affiche correctement son message d'indisponibilité sur le Web.
- **Contrôle de session enrichi (écran mode B, client Flutter)** : historique local des
  connexions (démarrages/arrêts de capture, connexion directe, diffusion Space, cast DLNA —
  persisté via `shared_preferences`, jamais synchronisé, `lib/features/projection/
  connection_history.dart`/`connection_history_service.dart`), carte « Diagnostic en direct »
  (adresse réseau, durée de capture — honnêtement marquée « durée inconnue » si la capture
  tournait déjà avant l'ouverture de l'écran plutôt que d'inventer une heure de départ,
  nombre de connexions actives, dernier événement), et confirmation avant d'arrêter la
  capture si une connexion directe/Space/DLNA est active (l'arrêt les couperait). `flutter
  analyze`/`flutter test` passent, y compris un test de bout en bout avec de vraies sockets en
  boucle locale (connexion directe journalisée dans l'historique et le diagnostic, dialogue de
  confirmation annulé puis accepté, remise à zéro après arrêt réel). Vérifié que l'écran reste
  fonctionnel dans un navigateur (le contenu Android de cet écran, diagnostic/historique
  inclus, est honnêtement indisponible hors Android — seul le message « disponible uniquement
  sur Android » y est vérifiable visuellement ; le reste est couvert par les tests).
- **QR code + partage du lien (mode B classique)** : QR code encodant l'adresse et bouton
  « Partager le lien » (menu de partage natif, Bluetooth inclus pour le *texte* de l'adresse, pas la
  vidéo) sur l'écran mode B. `flutter analyze`/`flutter test` passent.
- **Contrôle à distance (expérimental, mode B classique)** : un clic sur l'image dans le navigateur
  du récepteur rejoue un appui sur l'écran du téléphone, via un service d'accessibilité Android
  (`RemoteControlAccessibilityService.kt`, `dispatchGesture`, API publique depuis Android 7) que
  l'utilisateur doit activer manuellement. Désactivé par défaut, avec avertissement explicite :
  tant qu'il est actif, quiconque atteint l'adresse du flux peut contrôler l'écran (pas de
  confirmation par appui comme pour la connexion directe). `flutter analyze`/`flutter test` passent
  côté Dart ; **la partie native (dispatchGesture) n'a pas pu être testée sur un vrai geste** — pas
  de harnais de test instrumenté Android dans cet environnement, à vérifier sur appareil physique.
- **Smart TV (DLNA, prototype séparé)** : découverte UPnP/SSDP des récepteurs DLNA et envoi de
  l'adresse du flux (`SetAVTransportURI` + `Play`, bibliothèque `upnp_client`). Avantage sur la
  connexion directe : aucune app SWVERTEX requise sur la TV. **Compatibilité non garantie** : le
  flux MJPEG brut diffusé par le mode B n'est pas le format qu'attendent la plupart des récepteurs
  DLNA grand public (MP4/H.264 attendu plutôt qu'un multipart continu) — jamais vérifié contre une
  vraie Smart TV, qui n'est pas disponible dans cet environnement. `flutter analyze`/`flutter test`
  passent (découverte testée avec un service DLNA factice, sans réseau réel).
- **Miracast étudié et écarté** : diffusion d'écran native vers un PC/TV sans rien y installer.
  Recherché et confirmé bloqué par Android lui-même (pas un manque de temps) : l'API de diffusion
  Wi-Fi Display exige la permission système `CONFIGURE_WIFI_DISPLAY`, réservée aux apps signées avec
  la clé de l'OS. Aucune app tierce ne peut l'utiliser — non implémenté, et non implémentable sans
  être une app système.
- Rien d'autre en cours activement — en attente de la prochaine priorité : billing/paiements (bloqué
  par le §18), le mode A (module USB-C, bloqué par le §18), ou le câblage réel du mode B/C derrière
  un accessoire physique une fois les décisions matérielles prises.

## En attente (bloqué par une décision ou une dépendance)

- Module billing/abonnements : non commencé — attend les décisions du §18 (modèle commercial,
  prestataire de paiement).
- Une page/un article `SCHEDULED` ne bascule pas automatiquement en `PUBLISHED` à l'heure dite — il
  n'y a pas de worker/cron pour ça. Il faut appeler `publish` manuellement au bon moment, ou construire
  ce worker plus tard (nécessiterait Redis/BullMQ, déjà prévu dans l'architecture mais pas encore câblé).
- Notifications : aucun transport e-mail/push réel n'est branché (voir ci-dessus) ; aucun
  déclenchement automatique depuis les autres modules (inscription, facturation...) pour l'instant.
- Admin : tous les écrans prévus pour l'existant backend sont en place (comptes/rôles, accessoires,
  compatibilité, CMS, support, journal d'audit). Pas de rafraîchissement automatique du jeton expiré
  (15 min) — l'utilisateur doit se reconnecter manuellement.
- Client Flutter : l'authentification, la gestion des appareils, deux prototypes labo (mode B
  Android, mode C lentille), les Spaces (groupes de récepteurs), le contrôle de session
  enrichi et les sources Photos/Vidéos/Documents (voir « En cours ») existent. Les sources
  Présentations et Tableau blanc, ainsi que les implémentations finales des trois modes de
  projection, restent à faire.
- Mode A (module USB-C) : non démarré — dépend des décisions matérielles/commerciales du §18.
- Mode B (projecteur Wi-Fi) et Mode C (lentille) : prototypes labo en place (voir « En cours »),
  mais les implémentations finales (Miracast/DLNA pour B, accessoire optique réel pour C) dépendent
  des mêmes décisions, voir [docs/decisions-a-valider.md](docs/decisions-a-valider.md).

## Non testé

- Tests end-to-end HTTP automatisés (supertest) : pas encore écrits, seulement des tests unitaires avec
  mocks + une vérification manuelle ponctuelle du serveur réel.
- Comportement sous charge, scénarios de perte réseau, sécurité (CSRF/CORS/rate limiting) : pas encore
  implémentés ni testés.
- Prototype lentille (mode C) : vérifié par `flutter analyze`/`flutter test` et en navigateur
  (motif de calibrage, sélection d'image, orientations, luminosité qui échoue silencieusement sur
  web) ; jamais projeté à travers une vraie lentille optique — aucun accessoire disponible dans cet
  environnement, voir docs/decisions-a-valider.md.
## Risques techniques identifiés

- **`flutter run -d chrome`/`-d web-server` en mode debug ne fonctionne pas avec un navigateur piloté
  à distance** (ex. un agent qui ne peut pas établir la connexion de débogage websocket que Flutter
  attend) : le process reste bloqué sur "Waiting for connection from debug service". Pour vérifier le
  client web en dehors d'un vrai poste de développement, utiliser `flutter build web` puis servir
  `build/web` avec un serveur statique quelconque. Ne jamais réutiliser le même port pour un essai en
  mode debug puis un build statique sur la même origine : le service worker du premier reste parfois
  en cache et sert du contenu périmé même après un rechargement — changer de port si le comportement
  observé ne correspond pas au code actuel.
- **Le disque C: de ce poste est quasiment plein** (quelques Go libres seulement une fois le cache
  npm et le dossier Temp vidés). Le plus gros poste identifié est le disque virtuel WSL2 de Docker
  Desktop (~59 Go, ne se réduit jamais tout seul même après suppression d'images/conteneurs — il faut
  le compacter explicitement, pas fait ici faute d'accord explicite). Un disque plein a fait planter
  Docker Desktop en plein milieu de la session (conteneurs arrêtés, erreurs `ECONNREFUSED` du
  backend) ; il a suffi de relancer Docker Desktop une fois de l'espace libéré. Si des erreurs de
  connexion à la base de données réapparaissent sans raison apparente, vérifier l'espace disque et
  l'état de Docker Desktop avant de chercher un bug applicatif.
- **Ce dépôt est un vrai workspace npm (hoisting à la racine).** Exécuter `npm install` ou tout script
  npm depuis un sous-dossier (`services/backend`, `apps/site`) directement, au lieu de la racine avec
  `--workspace=...`, peut casser des dépendances transitives hoistées. Rencontré trois fois
  (`chokidar`, `ajv`, puis `es-toolkit` manquants) — la troisième fois, le `package-lock.json`
  lui-même s'est révélé corrompu (une dépendance déclarée dans un bloc `dependencies` d'un paquet
  sans jamais avoir sa propre entrée résolue dans le lockfile). Un `npm install` classique ne corrige
  pas ça : il faut supprimer `node_modules` **et** `package-lock.json`, puis réinstaller à neuf.
  Toujours lancer les commandes npm depuis la racine du monorepo, et si un module manquant réapparaît
  après un simple `rm -rf node_modules && npm install`, passer directement à la suppression du
  lockfile aussi plutôt que de boucler sur des réinstallations partielles.
- **Le port 3000 (Next.js par défaut) est déjà pris sur ce poste** par un autre projet de
  l'utilisateur ("Kokumba", un `web_admin` Next.js). Le site SWVERTEX tourne donc sur le port
  **3002** (`npm run dev`/`start --workspace=apps/site`), comme le backend tourne sur 3001 et
  Postgres sur 5433 pour la même raison. Ne jamais arrêter les processus Node d'un autre projet sur
  ce poste en nettoyant les processus de test.
- **Un guard/provider exporté d'un module (ex. `JwtAuthGuard`, `AdminPermissionGuard`) ne suffit pas à
  rendre ses propres dépendances résolubles dans le module consommateur.** Il faut aussi ré-exporter le
  module qui fournit chaque dépendance (`JwtModule` depuis `AuthModule` ; `UsersModule` depuis
  `RbacModule`). Sinon NestJS lève une `UnknownDependenciesException` au démarrage, pas à la
  compilation — rencontré deux fois, à vérifier systématiquement pour tout nouveau guard partagé.
- **Prisma 7 a changé son modèle de configuration** (plus de `datasource.url` dans `schema.prisma` ; la
  CLI lit `prisma.config.ts`, et `PrismaClient` nécessite un driver adapter — `@prisma/adapter-pg` pour
  PostgreSQL). Documenté dans `services/backend/prisma.config.ts` et `src/prisma/prisma.service.ts`.
  Ne pas suivre une documentation Prisma antérieure à la v7 sans vérifier ce point.
- **Le port PostgreSQL 5432 est déjà occupé sur ce poste par un service Windows natif
  "postgresql-x64-18"**, distinct de notre conteneur Docker. Le Postgres du projet est donc publié sur
  le port **5433** (voir `docker-compose.yml` et `.env.example`) pour ne pas interférer avec
  l'installation existante. Ne jamais modifier ou arrêter ce service natif sans autorisation explicite.
- Engine warning npm : Node 24.11.0 installé, certains paquets (NestJS 12 toolchain) demandent
  `^22.22.3 || ^24.15.0 || >=26.0.0`. Avertissement non bloquant observé jusqu'ici.
- 2 vulnérabilités npm modérées restantes, transitives à `@nestjs/cli` (outil de dev uniquement, via
  `minimatch`) ; le correctif proposé imposerait un retour à `@nestjs/cli@11`, non appliqué pour l'instant.
- Aucun matériel physique (module USB-C, projecteur Wi-Fi, lentille) disponible dans cet environnement :
  les modes A/B/C ne pourront être validés que sur banc de test réel, pas en développement pur logiciel.
