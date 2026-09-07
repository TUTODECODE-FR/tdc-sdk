# Tableau des contributions bénévoles — TDC-SDK

> **Source de vérité = [Issues GitLab](https://gitlab.com/tutodecode-org/tdc-sdk/-/issues/?label_name[]=benevolat)**  
> Label : `benevolat` (+ `wishlist` / `bug` / `proposition` selon le cas).

Ce fichier est un **index** (pas un tableau à éditer à la main).  
Le **Hub Communauté** de TDC Studio lit les issues en live via l’API GitLab.

## Flux bénévole (automatisé)

### 1. Proposer une idée / un bug

- **Hub Communauté** (TDC Studio) → *Proposer une idée* / *Un problème ?*  
  (jeton GitLab scope `api` → crée l’issue avec `benevolat` + `wishlist|bug|proposition`)
- **Ou** [nouvelle issue](https://gitlab.com/tutodecode-org/tdc-sdk/-/issues/new) → modèle **Proposition** ou **Bug_benevolat**  
  (labels préremplis). Le dropdown Type (Incident / Issue / Task) **n’accepte pas** de types custom sur GitLab.com : on s’appuie sur **modèles + labels**.

### 2. Prendre une tâche (`prendre #<iid>`)

Anti-collision : une seule personne peut être assignee. Le CI bloque une 2ᵉ claim.  
**Ne pas** ouvrir une issue « Prendre » pour claimer — le modèle *Prendre_une_tache* renvoie ici.

1. Choisir une issue **ouverte sans assignee** (statut « Libre » dans le Hub).
2. Créer la branche `volunteer/prendre-<iid>` (ex. `volunteer/prendre-42`).
3. Ajouter le marqueur `volunteer/claims/<iid>.md` contenant ton **pseudo GitLab** :

```markdown
username: ton-pseudo
```

4. Ouvrir une **Merge Request** dont le titre est **exactement** : `prendre #<iid>`  
   (ex. `prendre #42`). Modèle MR **Prendre** recommandé. **DCO** obligatoire.
5. Maxime (ou un reviewer) **valide / merge** la MR claim.

**Hub** : bouton *Préparer ma MR prendre* → deep-link GitLab (titre prérempli) + instructions.

### 3. Après le merge (automatique)

| Merge de… | Effet |
| :--- | :--- |
| Issue / discussion « Proposition » | ❌ ne réserve pas la tâche |
| MR `prendre #N` (titre +/ou `volunteer/claims/`) | ✅ CI assigne + `en-cours` |
| MR de **code** | ✅ ferme l’issue (livraison) |

Le job CI `volunteer_claim_apply` sur `main` :

1. détecte le claim (fichier marqueur et/ou titre `prendre #N`) — distinct des MR de code ;
2. assigne l’issue à l’auteur du claim ;
3. ajoute le label `en-cours`, retire `libre` s’il est présent.

Ensuite : coder sur une branche dédiée, MR de code classique, fermer l’issue au merge.

### 4. Garde anti-collision (MR)

Le job `volunteer_claim_validate` **échoue** si l’issue cible a déjà un **autre** assignee.  
Même auteur déjà assignee → OK (idempotent).

### Labels recommandés

| Label | Usage |
| :--- | :--- |
| `benevolat` | **Obligatoire** — apparaît dans le Hub / ce board |
| `wishlist` | Idée / amélioration |
| `proposition` | Proposition venue du Hub |
| `bug` | Anomalie |
| `libre` | Optionnel — disponible (retiré au claim) |
| `en-cours` | Posé automatiquement après merge du claim |
| `P1` / `P2` / `P3` | Priorité (optionnel) |

### Contact

Association TUTODECODE — [contact@tutodecode.org](mailto:contact@tutodecode.org) · [CONTRIBUTING.md](./CONTRIBUTING.md)

---

## Wishlist archivée (migration)

Les anciennes lignes markdown (TDC-001…TDC-012) sont dans  
[`docs/VOLUNTEER_BOARD_ARCHIVED.md`](./docs/VOLUNTEER_BOARD_ARCHIVED.md).

```bash
export GITLAB_TOKEN="glpat-…"   # scope api
python3 scripts/seed_volunteer_issues.py   # optionnel
```
