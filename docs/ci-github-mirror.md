# Mirroring GitLab → GitHub (TDC-SDK)

GitLab est la **source de vérité** (MR, validation, tags). GitHub sert uniquement aux **builds multi-OS** (Linux, Windows, macOS) via GitHub Actions.

## Flux

```
GitLab (main) → auto_tag → tag v* sur GitLab
       ↓
mirror_tag_to_github (ou push mirror GitLab) → tag v* sur GitHub
       ↓
GitHub Actions (.github/workflows/release.yml) → Release + binaires
       ↓
sync_github_multi_os_builds → télécharge les assets → échoue si problème
       ↓
release_gitlab → Release GitLab avec liens vers assets GitHub
```

## Variables CI GitLab (Settings → CI/CD → Variables)

| Variable | Scopes | Obligatoire | Rôle |
|----------|--------|-------------|------|
| `PROJECT_ACCESS_TOKEN` | `api`, `write_repository` | Non (auto_tag skip sinon) | Crée les tags `vX.Y.Z.N` sur main |
| `GITHUB_TOKEN` | PAT GitHub `repo` | Recommandé | Push tag vers GitHub + vérif statut Actions |
| `GITHUB_RELEASE_REPO` | — | Non | Défaut : `TUTODECODE-FR/tdc-sdk` |

## Push mirror GitLab (alternative au job CI)

Dans GitLab : **Settings → Repository → Mirroring repositories** → Push mirror vers `https://github.com/TUTODECODE-FR/tdc-sdk.git`.

Si le mirror propage les tags, `mirror_tag_to_github` skip (sans `GITHUB_TOKEN`) ou constate que le tag existe déjà.

## Codes d'erreur sync (`scripts/sync_github_release.sh`)

| Code | Cause | Action |
|------|-------|--------|
| `REPO_NOT_FOUND` | Repo GitHub absent ou privé sans token | Créer le repo / ajouter `GITHUB_TOKEN` |
| `TAG_NOT_MIRRORED` | Tag absent sur GitHub | Activer push mirror ou `GITHUB_TOKEN` |
| `GITHUB_ACTIONS_FAILED` | Workflow Release en échec | Voir Actions sur GitHub, corriger, re-tagger |
| `ASSETS_TIMEOUT` | Binaires non publiés à temps | Vérifier workflow `publish-release` |
| `ASSETS_MISSING` | Release sans binaires OS | Inspecter artifacts du workflow |

## Test manuel

1. Merger sur `main` avec `PROJECT_ACCESS_TOKEN` configuré → tag auto `vX.Y.Z.N`.
2. Ou tag manuel : `git tag -a v2.0.0.2 -s -m "test" && git push origin v2.0.0.2`
3. Vérifier pipeline tag GitLab : `mirror_tag_to_github` → `sync_github_multi_os_builds` → `release_gitlab`.
4. Sur GitHub : `gh run list -R TUTODECODE-FR/tdc-sdk --workflow "Release & Build"`.

## T2DECODE

Le dépôt T2DECODE a le workflow GitHub Release mais **pas encore** les jobs GitLab `mirror_tag_to_github` / `sync_github_multi_os_builds`. À aligner en follow-up.
