# Tableau des contributions bénévoles — [NOM DU DÉPÔT]

> **Template réutilisable** — Copier ce fichier à la racine sous le nom `VOLUNTEER_BOARD.md`, remplacer les placeholders `[...]`, puis lier depuis `CONTRIBUTING.md` et éventuellement `README.md`.
>
> Origine : [TDC-SDK/docs/VOLUNTEER_BOARD_TEMPLATE.md](https://gitlab.com/tutodecode-org/tdc-sdk/-/blob/main/docs/VOLUNTEER_BOARD_TEMPLATE.md)

Wishlist vivante des idées ouvertes sur **[NOM DU PROJET]**.

Ce fichier est une **liste d’idées** (pas un système de réservation). Le code se propose via une **Merge Request** classique avec DCO.

## Comment contribuer

1. **Choisir** une idée dont le statut est `Libre` (ou proposer une nouvelle ligne).
2. **Coder** sur une branche dédiée, commits avec **DCO** (`Signed-off-by: Prénom NOM <email>`).
3. **Ouvrir une MR** ; optionnel : mettre le lien dans **MR / Lien** et passer le statut à `En cours` / `Fait` au merge.

### Statuts

| Valeur | Signification |
| :--- | :--- |
| `Libre` | Idée ouverte |
| `En cours` | MR / travail déjà en cours |
| `Fait` | Mergé / terminé |
| `Bloqué` | En attente d’une décision ou d’une dépendance |

### Priorités

`P1` (urgent / fort impact) · `P2` (utile bientôt) · `P3` (nice-to-have)

### Contact

Association TUTODECODE — [contact@tutodecode.org](mailto:contact@tutodecode.org) · GitLab : `[groupe]/[projet]`

Guide : [CONTRIBUTING.md](../CONTRIBUTING.md) *(ajuster le chemin si besoin)*

---

## Backlog

| ID | Statut | Priorité | Titre | Description courte | Compétences | Note | MR / Lien |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| XXX-001 | Libre | P1 | [Titre court] | [Une phrase : quoi + pourquoi] | [ex. Flutter, Markdown] | — | — |
| XXX-002 | Libre | P2 | [Titre court] | [Une phrase] | [compétences] | — | — |
| XXX-003 | Libre | P3 | [Titre court] | [Une phrase] | [compétences] | — | — |

> Remplace le préfixe `XXX` par un code stable du dépôt (`T2D`, `PHANTOM`, `TDC`, …).

---

## Proposer une nouvelle idée

Ajoute une ligne en bas du tableau (ID suivant) via une MR, ou écris à [contact@tutodecode.org](mailto:contact@tutodecode.org).

Garde la description **courte** ; le détail technique va dans la MR.

---

## Checklist d’installation (autres repos)

- [ ] Copier ce fichier en `VOLUNTEER_BOARD.md` à la racine
- [ ] Remplir 8–12 idées réalistes (docs, UX, tests, i18n…)
- [ ] Ajouter en tête de `CONTRIBUTING.md` un lien vers `VOLUNTEER_BOARD.md`
- [ ] Optionnel : lien court dans `README.md` (section Contribuer)
- [ ] Première MR : `docs: add volunteer board` avec DCO `Signed-off-by`
