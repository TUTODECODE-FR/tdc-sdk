# Mirroring GitLab → GitHub (TDC-SDK)

GitLab est la **source de vérité** (MR, validation, tags). GitHub sert uniquement aux **builds multi-OS** (Linux, Windows, macOS) via GitHub Actions — **aucun `flutter build linux/windows/macos` sur les runners GitLab**.

**Quota Actions storage** : le forfait gratuit inclut ~2 Go d’artefacts/caches (distinct des minutes). Ne pas ajouter de workflows MR validate sur GitHub tant que le compte perso / org est saturé ; préférer nettoyer artefacts/caches ([billing](https://github.com/settings/billing)) ou migrer les releases vers l’org `TUTODECODE-FR` si un plan payant existe. Le stage MR `gate`/`validate` reste sur GitLab.

## Flux automatique : merge MR → release

```
1. Développeur ou relecteur merge la MR vers main
         ↓
2. Pipeline main (push) — job unique auto_tag (~1 min Alpine)
   → crée le tag vX.Y.Z.N sur le commit de merge (pubspec.yaml + suffixe incrémental)
         ↓
3. Pipeline tag v* — sync-os-builds + release uniquement (pas de validate)
   → mirror_tag_to_github pousse le tag vers GitHub (ou push mirror GitLab)
         ↓
4. GitHub Actions (.github/workflows/release.yml) — déclenché par push tag v*
   → build Linux + Windows + macOS → GitHub Release + binaires
         ↓
5. sync_github_multi_os_builds attend les assets GitHub (ou échoue avec code explicite)
         ↓
6. release_gitlab crée la Release GitLab avec liens vers les binaires GitHub
```

**Prérequis pour l'automatisation complète** : variable `PROJECT_ACCESS_TOKEN` (sinon `auto_tag` skip et il faut taguer à la main).

## Trois types de pipeline GitLab

| Déclencheur | Stages exécutés | Impact quota GitLab |
|-------------|-----------------|---------------------|
| **MR** (`merge_request_event`) | `gate` puis `validate` (fail-fast ; analyze/security GitLab) | Modéré — pas de build OS |
| **main** (push après merge) | `sync-os-builds` → `auto_tag` seul | Minimal (~1 min) |
| **tag** `v*` | `sync-os-builds` + `release` (mirror → sync → release_gitlab) | Faible — attente curl, pas de compile Flutter OS |

**Aucun job `build-test` / Android / Linux sur GitLab** : TDC Studio est desktop-only ;
les builds OS (Win / macOS / Linux) n’apparaissent **pas** dans l’UI MR — ils partent
sur GitHub Actions uniquement après acceptation du merge + tag `v*`.

Les branches feature **ne déclenchent pas** de pipeline (règle `workflow:`) — seules les MR, `main` et les tags consomment du quota.

## Variables CI GitLab (Settings → CI/CD → Variables)

| Variable | Scopes | Obligatoire | Rôle |
|----------|--------|-------------|------|
| `PROJECT_ACCESS_TOKEN` | `api`, `write_repository` | **Oui pour AUTO** | Crée les tags `vX.Y.Z.N` sur chaque push `main` (merge MR) |
| `GITHUB_TOKEN` | PAT GitHub `repo` | Recommandé | Push tag vers GitHub + vérif statut Actions |
| `GITHUB_RELEASE_REPO` | — | Non | Défaut : `TUTODECODE-FR/tdc-sdk` |
| `SF_PRIVATE_KEY` / `SF_USER` | — | Non | SourceForge (job `publish_sourceforge`, manual) |

### Créer `PROJECT_ACCESS_TOKEN`

1. GitLab → **Settings → Access tokens** → Project Access Token
2. Scopes : `api`, `write_repository`
3. **Settings → CI/CD → Variables** → `PROJECT_ACCESS_TOKEN` (masked)

### Créer `GITHUB_TOKEN`

1. GitHub → **Settings → Developer settings → PAT (classic)**
2. Scope : `repo`
3. Variable CI GitLab `GITHUB_TOKEN` (masked)

## Push mirror GitLab (alternative au job CI)

Dans GitLab : **Settings → Repository → Mirroring repositories** → Push mirror vers `https://github.com/TUTODECODE-FR/tdc-sdk.git`.

Si le mirror propage les tags, `mirror_tag_to_github` skip (sans `GITHUB_TOKEN`) ou constate que le tag existe déjà.

## GitHub Actions

Workflow : `.github/workflows/release.yml`

- **Trigger auto** : `push` tag `v*`
- **Trigger manuel** : `workflow_dispatch` (Actions → Release & Build → Run workflow)

## Codes d'erreur sync (`scripts/sync_github_release.sh`)

| Code | Cause | Action |
|------|-------|--------|
| `REPO_NOT_FOUND` | Repo GitHub absent ou privé sans token | Créer le repo / ajouter `GITHUB_TOKEN` |
| `TAG_NOT_MIRRORED` | Tag absent sur GitHub | Activer push mirror ou `GITHUB_TOKEN` |
| `GITHUB_ACTIONS_FAILED` | Workflow Release en échec | Voir Actions sur GitHub, corriger, re-tagger |
| `ASSETS_TIMEOUT` | Binaires non publiés à temps | Vérifier workflow `publish-release` |
| `ASSETS_MISSING` | Release sans binaires OS | Inspecter artifacts du workflow |

## Test manuel

1. Ouvrir une MR vers `main` → pipeline MR : jobs `validate` uniquement.
2. Merger la MR (auteur ou relecteur) → pipeline `main` : `auto_tag`.
3. Pipeline tag `vX.Y.Z.N` : `mirror_tag_to_github` → `sync_github_multi_os_builds` → `release_gitlab`.
4. Sur GitHub : `gh run list -R TUTODECODE-FR/tdc-sdk --workflow "Release & Build"`.

Tag manuel (sans merge) : `git tag -a v2.0.0.2 -s -m "test" && git push origin v2.0.0.2`

## Liens utiles

- GitLab MR : https://gitlab.com/tutodecode-org/tdc-sdk/-/merge_requests
- GitHub Actions : https://github.com/TUTODECODE-FR/tdc-sdk/actions/workflows/release.yml
- Releases GitHub : https://github.com/TUTODECODE-FR/tdc-sdk/releases

## T2DECODE

Le dépôt T2DECODE a le workflow GitHub Release mais **pas encore** les jobs GitLab `mirror_tag_to_github` / `sync_github_multi_os_builds`. À aligner en follow-up.
