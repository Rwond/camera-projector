# SWVERTEX CAMERA PROJECTOR

Écosystème logiciel et matériel de projection multi-mode (lentille optique, module USB-C, projecteur
Wi-Fi) avec applications mobiles/desktop, backend/cloud, administration web dédiée et site public
dynamique.

Spécification de référence : [docs/cahier-des-charges/Cahier_des_charges_SWVERTEX_CAMERA_PROJECTOR.pdf](docs/cahier-des-charges/Cahier_des_charges_SWVERTEX_CAMERA_PROJECTOR.pdf).

- Architecture et choix techniques : [ARCHITECTURE.md](ARCHITECTURE.md)
- Avancement (terminé / en cours / en attente / non testé) : [STATUS.md](STATUS.md)
- Décisions business/techniques en attente de validation : [docs/decisions-a-valider.md](docs/decisions-a-valider.md)

## Démarrage rapide (développement)

```bash
npm install
npm run docker:up        # PostgreSQL + Redis locaux
npm run dev:backend       # API NestJS en mode watch
```

## Structure

```
services/backend/   API NestJS (comptes, licences, appareils, CMS, admin, signaling)
apps/admin/          Back-office Next.js
apps/site/           Site public Next.js
apps/client/         Application Flutter (mobile + desktop/récepteur)
packages/            Code et actifs partagés
docs/                Documentation de référence
```
