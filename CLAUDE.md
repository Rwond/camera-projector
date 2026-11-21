# Consignes de travail — Camera Projector

## Dépôt GitHub de référence

- Compte GitHub : `Rwond`
- Dépôt : `https://github.com/Rwond/camera-projector`
- Visibilité attendue : **public**
- Branche de publication : `main`
- Remote Git : `origin`

Le dépôt `camera-projector` doit rester public. Ne jamais le rendre privé.
Avant toute modification de visibilité, vérifier la configuration réelle avec
`gh repo view Rwond/camera-projector --json visibility,defaultBranchRef,url`.

## Workflow après chaque tâche de développement

Dès que les modifications demandées sont prêtes :

1. **Vérifier les fichiers modifiés** avec `git status --short` et `git diff`.
   Contrôler qu'aucun fichier inattendu, temporaire ou personnel n'est inclus.
2. **Exécuter les tests ou vérifications pertinents** :
   - client Flutter : `cd apps/client` puis `flutter analyze` et `flutter test` ;
   - backend : `cd services/backend` puis `npm test` si le changement concerne le backend ;
   - admin ou site : `npm run lint` et `npm run build` si ces applications sont concernées.
3. **Vérifier qu'aucun secret ou fichier sensible ne sera publié** :
   `.env` réels, tokens, clés API, mots de passe, certificats privés, keystores,
   fichiers de signature et fichiers personnels. Seuls les `.env.example` sans
   secret réel peuvent être versionnés.
4. **Ajouter les modifications** avec des chemins explicites. Éviter `git add -A`
   sans avoir relu la liste des fichiers.
5. **Créer un commit** avec un message clair, descriptif et adapté aux
   modifications (en français, par exemple `Corrige...`, `Ajoute...`).
6. **Pousser automatiquement** sur `origin main` :
   `git push origin main`.
7. **Vérifier le push** avec `git status`, `git log -1 --oneline`,
   `git ls-remote --heads origin main` et
   `gh repo view Rwond/camera-projector --json visibility,defaultBranchRef,url`.

Ne pas demander systématiquement l'autorisation de faire un commit ou un push :
cela fait partie du workflow normal du projet.

## Fichiers à ne jamais pousser

- Secrets ou clés privées.
- Fichiers `.env` contenant des informations sensibles.
- Fichiers personnels ou de configuration locale.
- Fichiers temporaires, builds inutiles, APK/AAB, `node_modules`, `.dart_tool`,
  `.next`, `build`, `dist`, caches et fichiers de signature.
- Modifications non liées au projet.

Les fichiers `.env` locaux présents dans le dépôt de travail sont ignorés par
Git. Ne jamais les ajouter de force.

## En cas d'échec GitHub

Expliquer clairement la raison de l'échec, corriger si possible, puis vérifier à
nouveau le résultat. Ne jamais annoncer un push ou une publication comme réussis
sans vérification réelle. Ne pas utiliser `git push --force` sans demande
explicite de l'utilisateur.
