# apps/admin — Back-office SWVERTEX CAMERA PROJECTOR

Next.js (App Router), consomme exclusivement l'API privée de `services/backend`, avec RBAC et audit
côté serveur (§7-8 du cahier des charges). Jamais servi au public, jamais de domaine/session partagé
avec `apps/site`.

## Démarrage

```bash
cp .env.local.example .env.local
npm run dev --workspace=apps/admin   # depuis la racine du monorepo, port 3003
```

Toujours lancer les commandes npm depuis la racine du monorepo (voir STATUS.md — hoisting du
workspace).

## Authentification

Le jeton d'accès et le jeton de rafraîchissement sont posés en cookies **httpOnly** par un Server
Action (`src/app/login/actions.ts`), jamais exposés au JavaScript côté client. Tous les appels au
backend se font côté serveur (Server Components/Actions, `src/lib/api.ts`) — aucune requête vers
l'API ne part du navigateur, donc aucune configuration CORS n'est nécessaire pour cette app.

`src/proxy.ts` (convention « proxy », qui remplace `middleware.ts` dans cette version de Next.js)
redirige vers `/login` toute route sans jeton. Le backend revérifie le rôle à chaque requête
sensible ; une page qui reçoit un 403 l'affiche proprement au lieu de planter.

**Limite connue** : pas de rafraîchissement automatique du jeton expiré (15 minutes) — l'utilisateur
doit se reconnecter manuellement. Le tout premier Super Admin doit être promu par écriture directe
en base (voir STATUS.md), aucune voie d'auto-promotion n'est exposée.

## Pages

| Route | Contenu |
| --- | --- |
| `/login` | Connexion |
| `/` | Tableau de bord (utilisateur connecté) |
| `/audit-log` | Journal d'audit (`GET /admin/audit-log`), RBAC ressource `audit` |

Toutes les autres actions déjà prêtes côté backend (rôles, catalogue accessoires, compatibilité,
CMS, support, notifications) n'ont pas encore d'écran dédié — voir STATUS.md.
