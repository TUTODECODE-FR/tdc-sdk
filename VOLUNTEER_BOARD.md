# Tableau des contributions bénévoles — TDC-SDK

Wishlist vivante des idées ouvertes sur **TDC Studio**, le CLI `tdc`, l’extension VS Code et la doc du dépôt.

Ce fichier est une **liste d’idées** (pas un système de réservation). Les issues GitLab restent utiles pour discuter ; le code se propose via une **Merge Request** classique.

## Comment contribuer

**Via l’app TDC Studio** → lanceur → **Hub Communauté** (ou **Paramètres → Communauté / Bénévolat**) :

- consulter ce tableau (lecture) ;
- **Proposer une idée** ou **Signaler un bug** (jeton GitLab scope `api` requis pour l’envoi).

**Pour coder** : choisir une idée ci-dessous → branche dédiée → MR avec **DCO** (`Signed-off-by`). Pas de bouton « Je m’en occupe » dans l’app.

Optionnel (GitLab) : tu peux remplir **Note** / **MR / Lien** à la main dans une MR de doc si tu veux indiquer que tu travailles dessus — ce n’est pas obligatoire.

### Statuts

| Valeur | Signification |
| :--- | :--- |
| `Libre` | Idée ouverte |
| `En cours` | Quelqu’un a déjà une MR / un travail en cours |
| `Fait` | Mergé / terminé |
| `Bloqué` | En attente d’une décision ou d’une dépendance |

### Priorités

`P1` (urgent / fort impact) · `P2` (utile bientôt) · `P3` (nice-to-have)

### Contact

Association TUTODECODE — [contact@tutodecode.org](mailto:contact@tutodecode.org) · GitLab : [tutodecode-org/tdc-sdk](https://gitlab.com/tutodecode-org/tdc-sdk)

Guide : [CONTRIBUTING.md](./CONTRIBUTING.md)

---

## Backlog

| ID | Statut | Priorité | Titre | Description courte | Compétences | Note | MR / Lien |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| TDC-001 | Libre | P1 | Mettre à jour CONTRIBUTING (lanceur unifié) | Aligner CONTRIBUTING.md sur le lanceur TDC Studio v2 (Éditorial + Dev & Traduction, import, templates). | Markdown, produit | — | — |
| TDC-002 | Libre | P1 | Guide pas-à-pas Studio → export → MR | Rédiger un tutoriel court : créer/importer un `.tdc`, exporter vers `assets/`, ouvrir une MR GitLab avec DCO. | Rédaction, Git | — | — |
| TDC-003 | Libre | P2 | Relire l’onboarding Dev & Traduction | Vérifier les textes d’accueil / aide (Cheat Sheets, Locales, Export) et proposer des corrections claires. | UX writing, FR | — | — |
| TDC-004 | Libre | P2 | Template cours Cryptographie | Ajouter un template `.tdc` (course + modules + quiz) sur le thème crypto / PKI pour le lanceur « Partir d’un template ». | Pédagogie, `.tdc` | — | — |
| TDC-005 | Libre | P2 | Template cours Cloud | Idem pour un parcours Cloud (intro IaaS / containers), prêt à brancher dans le sélecteur de templates. | Pédagogie, `.tdc` | — | — |
| TDC-006 | Libre | P2 | Template cheat sheet Docker | Entrées `entry` Docker (build, run, compose…) exportables via Studio App. | Pédagogie, `.tdc` | — | — |
| TDC-007 | Libre | P2 | Template cheat sheet iptables / réseau | Entrées `entry` iptables / filtrage réseau, niveau débutant→intermédiaire. | Pédagogie, réseau | — | — |
| TDC-008 | Libre | P2 | Franciser les messages de validation `.tdc` | Remplacer / traduire les messages d’erreur parser & validation affichés dans Studio (FR cohérent). | Flutter/Dart, FR | — | — |
| TDC-009 | En cours | P2 | Empty state quiz guidé | Quand un module n’a pas de quiz, afficher un empty state avec CTA « Ajouter un quiz » plutôt qu’une section absente. | Flutter, UX | @CavaleriCristina | — |
| TDC-010 | Libre | P3 | Panneau d’aide mode Éditorial | Ajouter / enrichir un panneau d’aide contextuelle dans l’éditeur de cours (raccourcis, structure `.tdc`). | Flutter, UX writing | — | — |
| TDC-011 | Libre | P2 | Import cheat sheets : conserver les `warnings` | À l’import d’un `.tdc` d’entrées, ne pas perdre les champs `warnings` / métadonnées déjà présentes. | Dart, parser | — | — |
| TDC-012 | Libre | P3 | Aperçu import cours plus riche | Enrichir l’aperçu « Importer un cours .tdc » (modules, quiz, durée) avant export. | Flutter, UX | — | — |

---

## Proposer une nouvelle idée

- Depuis le **Hub Communauté** de TDC Studio, ou
- Ajoute une ligne en bas du tableau (ID suivant : `TDC-013`, …) via une MR, ou
- Écris à [contact@tutodecode.org](mailto:contact@tutodecode.org).

Garde la description **courte** (une phrase) ; le détail technique va dans la MR.
