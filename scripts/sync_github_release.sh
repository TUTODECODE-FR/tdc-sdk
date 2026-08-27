#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>
# Pull multi-OS release assets from GitHub Actions back to GitLab CI.
# Exit codes and messages are explicit so pipeline failures are actionable.

set -euo pipefail

TAG="${CI_COMMIT_TAG:-${TAG:?Variable TAG ou CI_COMMIT_TAG requise}}"
REPO="${GITHUB_RELEASE_REPO:-TUTODECODE-FR/tdc-sdk}"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"
ASSETS_DIR="${ASSETS_DIR:-github_assets}"
MAX_WAIT="${MAX_WAIT:-90}"
WAIT_INTERVAL="${WAIT_INTERVAL:-20}"
WORKFLOW_NAME="${GITHUB_WORKFLOW_NAME:-Release & Build}"

REQUIRED_PROBE=(
  "TDC-Studio-macOS.dmg"
  "TDC-Studio-Linux.tar.gz"
  "TDC-Studio-Windows.zip"
)

ALL_ASSETS=(
  "TDC-Studio-Linux.tar.gz"
  "TDC-Studio-Windows.zip"
  "TDC-Studio-macOS.dmg"
  "TDC-Studio-macOS.zip"
  "sbom-cyclonedx.json"
  "sbom-spdx.json"
  "SHA256SUMS.txt"
)

fail() {
  local code="$1"
  local cause="$2"
  local action="$3"
  echo ""
  echo "=========================================================="
  echo "❌ ÉCHEC SYNC GITHUB [$code]"
  echo "   Tag     : $TAG"
  echo "   Repo    : $REPO"
  echo "   Cause   : $cause"
  echo "   Action  : $action"
  echo "=========================================================="
  exit 1
}

gh_curl() {
  local url="$1"
  shift
  if [ -n "$GITHUB_TOKEN" ]; then
    curl -fsSL "$@" -H "Authorization: Bearer ${GITHUB_TOKEN}" -H "Accept: application/vnd.github+json" "$url"
  else
    curl -fsSL "$@" -H "Accept: application/vnd.github+json" "$url"
  fi
}

gh_curl_code() {
  local url="$1"
  shift
  if [ -n "$GITHUB_TOKEN" ]; then
    curl -sS "$@" -o /dev/null -w "%{http_code}" \
      -H "Authorization: Bearer ${GITHUB_TOKEN}" \
      -H "Accept: application/vnd.github+json" \
      "$url"
  else
    curl -sS "$@" -o /dev/null -w "%{http_code}" \
      -H "Accept: application/vnd.github+json" \
      "$url"
  fi
}

echo "=========================================================="
echo "🔄 Sync GitHub → GitLab — builds multi-OS"
echo "   Tag  : $TAG"
echo "   Repo : $REPO"
echo "=========================================================="

# 1. GitHub repo exists
REPO_HTTP=$(gh_curl_code "https://api.github.com/repos/${REPO}")
case "$REPO_HTTP" in
  200) echo "✅ Dépôt GitHub accessible" ;;
  404)
    fail "REPO_NOT_FOUND" \
      "Le dépôt github.com/${REPO} n'existe pas ou est privé sans GITHUB_TOKEN." \
      "Créer le repo GitHub miroir ou ajouter GITHUB_TOKEN (scope repo) en variable CI GitLab."
    ;;
  401|403)
    fail "REPO_ACCESS_DENIED" \
      "Accès refusé au dépôt (HTTP ${REPO_HTTP})." \
      "Vérifier GITHUB_TOKEN : Personal Access Token avec scope repo sur ${REPO}."
    ;;
  *)
    fail "REPO_CHECK_HTTP_ERROR" \
      "Impossible de vérifier le dépôt (HTTP ${REPO_HTTP})." \
      "Réessayer plus tard ou vérifier api.github.com et le token CI."
    ;;
esac

# 2. Tag mirrored on GitHub
TAG_HTTP=$(gh_curl_code "https://api.github.com/repos/${REPO}/git/ref/tags/${TAG}")
if [ "$TAG_HTTP" = "404" ]; then
  fail "TAG_NOT_MIRRORED" \
    "Le tag ${TAG} n'est pas présent sur GitHub." \
    "Activer le push mirror GitLab→GitHub OU le job mirror_tag_to_github (variable GITHUB_TOKEN)."
elif [ "$TAG_HTTP" != "200" ]; then
  fail "TAG_CHECK_HTTP_ERROR" \
    "Vérification du tag échouée (HTTP ${TAG_HTTP})." \
    "Contrôler GITHUB_TOKEN et que le tag ${TAG} a bien été poussé sur GitHub."
fi
echo "✅ Tag ${TAG} présent sur GitHub"

# 3. GitHub Actions workflow status (optional but informative)
if [ -n "$GITHUB_TOKEN" ]; then
  RUNS_JSON=$(gh_curl "https://api.github.com/repos/${REPO}/actions/runs?event=push&per_page=10" || echo "{}")
  # Prefer run for this tag ref
  RUN_ID=$(echo "$RUNS_JSON" | grep -B5 "\"name\":\"${TAG}\"" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2 || true)
  if [ -z "$RUN_ID" ]; then
    RUN_ID=$(echo "$RUNS_JSON" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2 || true)
  fi
  if [ -n "$RUN_ID" ]; then
    RUN_DETAIL=$(gh_curl "https://api.github.com/repos/${REPO}/actions/runs/${RUN_ID}" || echo "{}")
    RUN_STATUS=$(echo "$RUN_DETAIL" | grep -o '"status":"[^"]*"' | head -1 | cut -d'"' -f4 || echo "unknown")
    RUN_CONCL=$(echo "$RUN_DETAIL" | grep -o '"conclusion":"[^"]*"' | head -1 | cut -d'"' -f4 || echo "")
    echo "ℹ️  Dernier workflow GitHub Actions : status=${RUN_STATUS} conclusion=${RUN_CONCL:-n/a}"
    if [ "$RUN_STATUS" = "in_progress" ] || [ "$RUN_STATUS" = "queued" ] || [ "$RUN_STATUS" = "waiting" ]; then
      echo "⏳ Workflow GitHub encore en cours — attente des binaires..."
    elif [ "$RUN_CONCL" = "failure" ] || [ "$RUN_CONCL" = "cancelled" ]; then
      fail "GITHUB_ACTIONS_FAILED" \
        "Le workflow « ${WORKFLOW_NAME} » a échoué (conclusion=${RUN_CONCL})." \
        "Consulter https://github.com/${REPO}/actions — corriger le build puis re-lancer le pipeline tag."
    fi
  fi
else
  echo "ℹ️  GITHUB_TOKEN absent — statut Actions non vérifié (API publique limitée)."
fi

# 4. Wait for release assets
BASE="https://github.com/${REPO}/releases/download/${TAG}"
mkdir -p "$ASSETS_DIR"
ASSETS_READY=0

echo "⏳ Attente publication GitHub Release (${MAX_WAIT}×${WAIT_INTERVAL}s max)..."
for i in $(seq 1 "$MAX_WAIT"); do
  for probe in "${REQUIRED_PROBE[@]}"; do
    if curl -fsSL -I "${BASE}/${probe}" >/dev/null 2>&1; then
      ASSETS_READY=1
      echo "✅ Binaires détectés (${probe}) après ${i} tentative(s)."
      break 2
    fi
  done
  echo "   Compilation GitHub en cours (Linux/Windows/macOS)... (${i}/${MAX_WAIT})"
  sleep "$WAIT_INTERVAL"
done

if [ "$ASSETS_READY" -eq 0 ]; then
  fail "ASSETS_TIMEOUT" \
    "Aucun binaire multi-OS trouvé après $((MAX_WAIT * WAIT_INTERVAL))s sur ${BASE}/." \
    "Vérifier que .github/workflows/release.yml s'est déclenché sur le tag ${TAG} et que publish-release a réussi."
fi

# 5. Download assets
DOWNLOADED=0
MISSING=""
for asset in "${ALL_ASSETS[@]}"; do
  dest="${ASSETS_DIR}/${asset}"
  if curl -fsSL "${BASE}/${asset}" -o "$dest"; then
    echo "✅ ${asset}"
    DOWNLOADED=$((DOWNLOADED + 1))
  else
    echo "⚠️  ${asset} indisponible"
    MISSING="${MISSING} ${asset}"
  fi
done

# Require at least one OS binary downloaded
OS_OK=0
for probe in "${REQUIRED_PROBE[@]}"; do
  if [ -f "${ASSETS_DIR}/${probe}" ]; then
    OS_OK=1
    break
  fi
done

if [ "$OS_OK" -eq 0 ]; then
  fail "ASSETS_MISSING" \
    "Release GitHub trouvée mais aucun binaire OS téléchargé.${MISSING:+ Manquants:${MISSING}}" \
    "Contrôler les artifacts du workflow GitHub Actions pour le tag ${TAG}."
fi

echo ""
echo "✅ Sync terminée — ${DOWNLOADED} fichier(s) dans ${ASSETS_DIR}/"
ls -lh "$ASSETS_DIR/" || true
