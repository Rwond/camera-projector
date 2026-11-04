# Architecture — SWVERTEX CAMERA PROJECTOR

Référence fonctionnelle : [docs/cahier-des-charges/Cahier_des_charges_SWVERTEX_CAMERA_PROJECTOR.pdf](docs/cahier-des-charges/Cahier_des_charges_SWVERTEX_CAMERA_PROJECTOR.pdf).
Ce document explique les choix structurants et pourquoi ils ont été faits. Il doit être tenu à jour à chaque décision d'architecture importante.

## Vue d'ensemble du monorepo

```
services/backend/   NestJS + Prisma + PostgreSQL + Redis — API privée (admin/RBAC), API publique (site/CMS),
                     signaling temps réel, licences/abonnements, support, audit.
apps/admin/          Next.js — back-office SWVERTEX (consomme l'API privée uniquement).
apps/site/           Next.js — site public dynamique (consomme l'API publique/CMS uniquement).
apps/client/         Flutter — application unique multi-cible (Android, iOS, Windows, macOS, Web) pour
                     mobile ET desktop/récepteur, avec modules natifs par plateforme.
packages/shared/     Types et contrats partagés (DTO, enums) entre backend et apps web.
packages/brand-assets/ Logo, favicons, manifest — actifs de marque réutilisables par site et admin.
docs/                 Cahier des charges, décisions à valider, notes d'architecture complémentaires.
```

## Pourquoi ces choix

- **Un backend unique (NestJS/TypeScript), pas un par domaine** : le produit est encore un seul service métier (comptes, licences, appareils, CMS) ; un découpage en micro-services maintenant ajouterait de la complexité opérationnelle sans bénéfice réel. Le découpage se fait en **modules Nest** (un par domaine du §6-7-9 du cahier des charges), ce qui permet d'extraire un module en service séparé plus tard si la charge l'exige, sans réécriture.
- **PostgreSQL + Prisma** : base relationnelle adaptée aux données métier (comptes, licences, facturation, audit) exigées par le cahier des charges (§12) ; Prisma donne des migrations versionnées et un typage de bout en bout avec TypeScript.
- **Redis** : sessions courtes, limitation de débit, files de tâches asynchrones (notifications, webhooks) — exigé explicitement en §5 "Architecture technique cible".
- **Admin et site = deux apps Next.js séparées, pas une seule avec des routes protégées** : le cahier des charges interdit que le public atteigne les fonctions internes (§7, §9). Séparer physiquement les deux apps rend cette frontière vérifiable au niveau réseau/déploiement, pas seulement par un middleware applicatif qui peut avoir un bug.
- **Un seul client Flutter pour mobile + desktop/récepteur** : Flutter supporte nativement Android/iOS/Windows/macOS/Web depuis une seule codebase. Cela évite de dupliquer la logique UI, de session et de signaling sur quatre plateformes. Tout ce que Flutter ne peut pas faire nativement (CameraX, AVFoundation, MediaProjection, ReplayKit, ScreenCaptureKit, Windows Graphics Capture, USB-C, découverte réseau) passe par des **canaux de plateforme (platform channels)** derrière une interface Dart commune — afin qu'une limite d'une plateforme n'affecte jamais le contrat des autres.
- **Vidéo hors du backend métier** : conformément au §1.2 ("principes non négociables") et §5.1, les flux audio/vidéo circulent en pair-à-pair (WebRTC, ICE/STUN, TURN en secours) directement entre les appareils ; le backend ne fait que le *signaling* (négociation WebSocket) et reçoit des métadonnées minimales, jamais le contenu. Une panne du backend n'interrompt donc pas une session locale déjà établie.
- **RBAC vérifié côté serveur uniquement** : chaque module backend doit exposer des guards/permissions réutilisables ; masquer un bouton côté admin ne constitue jamais un contrôle d'accès (exigence explicite du §8).

## Modèle de données (point de départ, §12 du cahier des charges)

Le schéma Prisma initial (`services/backend/prisma/schema.prisma`) couvre les entités du §12 : `User`, `Organization`, `Role`/`Permission`, `Device`, `Accessory`, `CompatibilityRecord`, `ProjectionSession`, `Plan`/`Subscription`, `Transaction`/`Invoice`, `SupportTicket`, `AppRelease`/`FirmwareRelease`, `CmsPage`/`Media`/`Article`, `AuditLog`. Il sera normalisé/étendu pendant la conception technique de chaque module, au fur et à mesure de leur implémentation réelle (pas de champ spéculatif ajouté sans module qui l'utilise).

## État d'avancement

Voir [STATUS.md](STATUS.md) — mis à jour à chaque session de travail. Aucune fonctionnalité n'y est marquée "terminée" sans être implémentée ET testée.

## Décisions ouvertes

Voir [docs/decisions-a-valider.md](docs/decisions-a-valider.md) — reprises du §18 du cahier des charges, à trancher avant d'engager les phases qui en dépendent.
