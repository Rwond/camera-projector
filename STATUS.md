# État d'avancement — SWVERTEX CAMERA PROJECTOR

Convention : une ligne passe en **Terminé** seulement si elle est implémentée ET testée (automatiquement ou manuellement, avec preuve). "Scaffold" = structure posée, aucune logique métier encore écrite.

Dernière mise à jour : 2026-11-04.

## Terminé

- Socle monorepo : structure de dossiers, workspaces npm, Docker Compose (Postgres 17 + Redis 7),
  `.gitignore`, CI GitHub Actions pour le backend (`.github/workflows/backend-ci.yml`).
- Backend NestJS scaffoldé, compile (`npm run build`) et démarre.
- Schéma Prisma initial (§12 du cahier des charges) : migration `init` créée et appliquée sur la base
  de développement.
- Module `health` : `GET /health` (liveness) et `GET /health/db` (ping base de données réelle) — 5 tests
  unitaires passants.
- Module `users` : `UsersService` (recherche par e-mail/id, création) — 2 tests unitaires passants.
- Module `auth` : `POST /auth/register` et `POST /auth/login`, hash bcrypt, émission de JWT
  access/refresh — 7 tests unitaires passants. Vérifié manuellement en conditions réelles (serveur
  démarré, base de données de développement, requêtes HTTP réelles).
- 15 tests automatisés passants au total ; lint (`oxlint`) sans erreur.

## En cours

- Rien en cours activement — en attente de la prochaine priorité (RBAC admin, ou organisations/devices).

## En attente (bloqué par une décision ou une dépendance)

- Modules métier restants (organizations, devices, accessories, compatibility, billing, notifications,
  support, cms, audit, RBAC admin) : non commencés.
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
