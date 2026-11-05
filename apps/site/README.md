# apps/site — Site public SWVERTEX CAMERA PROJECTOR

Next.js (App Router), contenu piloté par le CMS via l'API publique de `services/backend` (§9 du
cahier des charges). Aucun accès aux fonctions internes ou aux données privées — seulement ce qui
est explicitement publié.

## Démarrage

```bash
cp .env.local.example .env.local
npm run dev --workspace=apps/site   # depuis la racine du monorepo, port 3002
```

Le port 3000 par défaut de Next.js est déjà utilisé par un autre projet sur ce poste ; `npm run
dev`/`start` sont donc configurés sur le port **3002**. Toujours lancer les commandes npm depuis la
racine du monorepo (voir STATUS.md — hoisting du workspace).

## Pages

| Route | Source |
| --- | --- |
| `/` | Page CMS de slug `accueil` |
| `/compatibilite` | Matrice de compatibilité publique (`GET /compatibility`) |
| `/actualites`, `/actualites/:slug` | Articles de catégorie `NEWS` |
| `/guides`, `/guides/:slug` | Articles de catégorie `GUIDE` et `FAQ` |
| `/:slug` | Toute autre page CMS publiée (route générique) |

Le contenu des pages/articles est un objet `{ blocks: Block[] }` (voir `src/lib/types.ts` et
`src/components/BlockRenderer.tsx`) : types de blocs pris en charge pour l'instant — `heading`,
`text`, `cta`, `image`.
