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
- 73 tests automatisés passants ; lint (`oxlint`) sans erreur ; vérifié manuellement en conditions
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
  trois actions effectuées), et flux CMS complet (délégation CONTENT_MANAGER→création de page en
  brouillon invisible du public en 404→publication→visible du public en 200→un rôle sans permission
  cms refusé en 403→articles publiés filtrables par catégorie→dépublication d'un article disparaît
  bien de la liste publique→programmation future acceptée, programmation passée refusée en 400, page
  programmée toujours invisible du public→enregistrement d'un média).

## En cours

- Rien en cours activement — en attente de la prochaine priorité (billing/paiements, ou pages du site
  public restantes : tarifs, téléchargements, support).

## En attente (bloqué par une décision ou une dépendance)

- Modules métier restants (billing, notifications, support) : non commencés.
- Une page/un article `SCHEDULED` ne bascule pas automatiquement en `PUBLISHED` à l'heure dite — il
  n'y a pas de worker/cron pour ça. Il faut appeler `publish` manuellement au bon moment, ou construire
  ce worker plus tard (nécessiterait Redis/BullMQ, déjà prévu dans l'architecture mais pas encore câblé).
- Apps Next.js `admin` et `site` : non démarrées.
- Client Flutter (`apps/client`) : non démarré.
- Mode A (module USB-C), Mode B (projecteur Wi-Fi), Mode C (lentille) : non démarrés — dépendent de
  décisions matérielles/commerciales, voir [docs/decisions-a-valider.md](docs/decisions-a-valider.md).

## Non testé

- Tests end-to-end HTTP automatisés (supertest) : pas encore écrits, seulement des tests unitaires avec
  mocks + une vérification manuelle ponctuelle du serveur réel.
- Comportement sous charge, scénarios de perte réseau, sécurité (CSRF/CORS/rate limiting) : pas encore
  implémentés ni testés.

## Risques techniques identifiés

- **Ce dépôt est un vrai workspace npm (hoisting à la racine).** Exécuter `npm install` ou tout script
  npm depuis `services/backend` directement (au lieu de la racine avec `--workspace=services/backend`)
  peut casser des dépendances transitives hoistées (vécu deux fois : `chokidar` puis `ajv` manquants
  après un `npm install` lancé depuis le mauvais dossier). Toujours lancer les commandes npm du backend
  depuis la racine du monorepo.
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
