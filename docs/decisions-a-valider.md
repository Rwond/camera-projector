# Décisions à valider avant développement

Reprises du §18 du cahier des charges. Aucune ne bloque le socle technique actuel (schéma de données
générique), mais chacune conditionne une phase ultérieure précise — indiquée entre parenthèses.

- [ ] **Téléphones/OS de référence** (Android/iOS versions, ordinateurs de référence) — conditionne la
      matrice de compatibilité et les tests (phases 1, 7).
- [ ] **Projecteurs Wi-Fi tiers prioritaires** et protocoles légalement accessibles — conditionne le
      Mode B (phase 2).
- [ ] **Moteur optique OEM/ODM** pour le module USB-C, résolution/luminosité minimales visées —
      conditionne le Mode A (phase 3).
- [ ] **Alimentation du module A** : externe, batterie intégrée, ou les deux — conditionne le Mode A
      (phase 3) et la sécurité matérielle (§10.4).
- [ ] **Commandes matériel réellement exposées par le firmware** du module A — conditionne le protocole
      de commande et l'intégration logicielle (phase 3).
- [ ] **Politique commerciale** : gratuit / essai / abonnement / licence permanente / vente d'accessoires
      / combinaison — conditionne le modèle `Plan`/`Subscription` définitif et l'admin (phase 5).
- [ ] **Prestataire de paiement, devises, taxes, marchés ciblés** — conditionne l'intégration paiement
      (phase 5). Note : Stripe est le choix par défaut le plus courant pour ce type de produit
      (abonnements + facturation + webhooks signés) sauf préférence contraire.
- [ ] **Durées de conservation des données, politique de diagnostic, exigences réglementaires par
      marché** — conditionne la politique de confidentialité et la base légale (§10.3).
- [ ] **Langues du site, identité visuelle définitive, nom de domaine, canaux de distribution** —
      conditionne le site public et le CMS (phase 6). Le cahier des charges fixe déjà le français comme
      langue initiale avec extension prévue à l'anglais (§9.3).

Statut : aucune réponse reçue à ce jour. À soulever avant d'engager les phases 2, 3 et 5 en particulier.
