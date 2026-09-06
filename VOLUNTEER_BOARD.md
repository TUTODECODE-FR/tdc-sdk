# Tableau des contributions bénévoles — TDC-SDK

> **Source de vérité = [Issues GitLab](https://gitlab.com/tutodecode-org/tdc-sdk/-/issues/?label_name[]=benevolat)**  
> Label : `benevolat` (+ `wishlist` / `bug` / `proposition` selon le cas).

Ce fichier est un **index** (pas un tableau à éditer à la main).  
Le **Hub Communauté** de TDC Studio lit les issues en live via l’API GitLab.

## Comment contribuer (sans édition manuelle)

1. **Consulter** les [issues `benevolat`](https://gitlab.com/tutodecode-org/tdc-sdk/-/issues/?label_name[]=benevolat) — ou le Hub dans TDC Studio.
2. **Proposer** une idée / **signaler** un bug : depuis le Hub (jeton scope `api`) ou en créant une issue avec le label `benevolat`.
3. **Coder** : branche + **Merge Request** avec DCO (`Signed-off-by`). Pas de colonne « Pris par » à remplir.

Assignees GitLab = travail en cours (optionnel). Fermer l’issue au merge.

### Labels recommandés

| Label | Usage |
| :--- | :--- |
| `benevolat` | **Obligatoire** — apparaît dans le Hub / ce board |
| `wishlist` | Idée / amélioration |
| `proposition` | Proposition venue du Hub |
| `bug` | Anomalie |
| `P1` / `P2` / `P3` | Priorité (optionnel) |

### Contact

Association TUTODECODE — [contact@tutodecode.org](mailto:contact@tutodecode.org) · [CONTRIBUTING.md](./CONTRIBUTING.md)

---

## Wishlist archivée (migration)

Les anciennes lignes markdown (TDC-001…TDC-012) sont dans  
[`docs/VOLUNTEER_BOARD_ARCHIVED.md`](./docs/VOLUNTEER_BOARD_ARCHIVED.md).

Pour les republier comme issues (mainteneurs) :

```bash
export GITLAB_TOKEN="glpat-…"   # scope api
python3 scripts/seed_volunteer_issues.py   # optionnel
```

Ou créer manuellement une issue par idée avec label `benevolat,wishlist`.
