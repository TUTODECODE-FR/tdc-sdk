# Tableau des contributions bénévoles — [NOM DU DÉPÔT]

> **Template réutilisable** — Copier ce fichier à la racine sous le nom `VOLUNTEER_BOARD.md`, remplacer les placeholders `[...]`, puis lier depuis `CONTRIBUTING.md` et éventuellement `README.md`.
>
> Origine : [TDC-SDK/docs/VOLUNTEER_BOARD_TEMPLATE.md](https://gitlab.com/tutodecode-org/tdc-sdk/-/blob/main/docs/VOLUNTEER_BOARD_TEMPLATE.md)

Cahier des charges vivant des améliorations ouvertes sur **[NOM DU PROJET]**.

Ce fichier est la **source de vérité** pour savoir qui travaille sur quoi. Les issues du tracker restent optionnelles ; le suivi des claims bénévoles se fait ici.

## Comment ça marche

1. **Choisir** une ligne dont le statut est `Libre`.
2. **Réclamer** : ouvrir une MR (ou un commit sur une branche) qui met ton pseudo GitLab/GitHub dans la colonne **Pris par**, et passe le statut à `En cours`.
3. **Travailler** : une tâche = une Merge Request, branche dédiée, commits avec **DCO** (`Signed-off-by: Prénom NOM <email>`).
4. **Livrer** : mettre le lien de la MR dans **MR / Lien**, puis passer le statut à `Fait` au merge (ou laisser un mainteneur le faire).
5. **Abandonner** : retirer ton pseudo, remettre `Libre`, et laisser un mot dans la description si besoin.

### Statuts

| Valeur | Signification |
| :--- | :--- |
| `Libre` | À prendre |
| `En cours` | Quelqu’un travaille dessus |
| `Fait` | Mergé / terminé |
| `Bloqué` | En attente d’une décision ou d’une dépendance |

### Priorités

`P1` (urgent / fort impact) · `P2` (utile bientôt) · `P3` (nice-to-have)

### Contact

Association TUTODECODE — [contact@tutodecode.org](mailto:contact@tutodecode.org) · GitLab : `[groupe]/[projet]`

Guide détaillé : [CONTRIBUTING.md](../CONTRIBUTING.md) *(ajuster le chemin si besoin)*

---

## Backlog

| ID | Statut | Priorité | Titre | Description courte | Compétences | Pris par | MR / Lien |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| XXX-001 | Libre | P1 | [Titre court] | [Une phrase : quoi + pourquoi] | [ex. Flutter, Markdown] | — | — |
| XXX-002 | Libre | P2 | [Titre court] | [Une phrase] | [compétences] | — | — |
| XXX-003 | Libre | P3 | [Titre court] | [Une phrase] | [compétences] | — | — |

> Remplace le préfixe `XXX` par un code stable du dépôt (`T2D`, `PHANTOM`, `TDC`, …).

---

## Proposer une nouvelle tâche

Ajoute une ligne en bas du tableau (ID suivant) via une MR, ou écris à [contact@tutodecode.org](mailto:contact@tutodecode.org).

Garde la description **courte** ; le détail technique va dans la MR.

---

## Checklist d’installation (autres repos)

- [ ] Copier ce fichier en `VOLUNTEER_BOARD.md` à la racine
- [ ] Remplir 8–12 tâches réalistes (docs, UX, tests, i18n…)
- [ ] Ajouter en tête de `CONTRIBUTING.md` un lien « source de vérité = VOLUNTEER_BOARD.md »
- [ ] Optionnel : lien court dans `README.md` (section Contribuer)
- [ ] Première MR : `docs: add volunteer board` avec DCO `Signed-off-by`
