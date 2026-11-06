# État d'avancement — SWVERTEX CAMERA PROJECTOR

Convention : une ligne passe en **Terminé** seulement si elle est implémentée ET testée (automatiquement ou manuellement, avec preuve). "Scaffold" = structure posée, aucune logique métier encore écrite.

Dernière mise à jour : 2026-11-05.

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

## En cours

- Rien en cours activement — en attente de la prochaine priorité (billing/paiements, ou client
  Flutter — l'admin couvre désormais toutes les actions backend construites jusqu'ici, à l'exception
  du billing qui attend les décisions du §18).

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
- Client Flutter (`apps/client`) : non démarré.
- Mode A (module USB-C), Mode B (projecteur Wi-Fi), Mode C (lentille) : non démarrés — dépendent de
  décisions matérielles/commerciales, voir [docs/decisions-a-valider.md](docs/decisions-a-valider.md).

## Non testé

- Tests end-to-end HTTP automatisés (supertest) : pas encore écrits, seulement des tests unitaires avec
  mocks + une vérification manuelle ponctuelle du serveur réel.
- Comportement sous charge, scénarios de perte réseau, sécurité (CSRF/CORS/rate limiting) : pas encore
  implémentés ni testés.

## Risques techniques identifiés

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
