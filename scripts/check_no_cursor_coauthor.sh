#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>
#
# Forward protection: refuse commits that add a Cursor co-author trailer.
# Does NOT rewrite history — only checks commits about to be pushed / in an MR.
#
# Usage (local):
#   scripts/check_no_cursor_coauthor.sh
#   scripts/check_no_cursor_coauthor.sh origin/main..HEAD
#
# Optional git hook sample:
#   ln -sf ../../scripts/hooks/commit-msg.sample .git/hooks/commit-msg
#   # or copy scripts/hooks/commit-msg.sample → .git/hooks/commit-msg
set -euo pipefail

RANGE="${1:-}"
PATTERN='Co-authored-by:[[:space:]]*Cursor[[:space:]]*<'

if [[ -z "$RANGE" ]]; then
  if git rev-parse --verify origin/main >/dev/null 2>&1; then
    RANGE="origin/main..HEAD"
  else
    RANGE="HEAD"
  fi
fi

echo "Checking commits in range: $RANGE"
FOUND=0
while IFS= read -r commit; do
  [[ -z "$commit" ]] && continue
  if git log -1 --format=%B "$commit" | grep -Eiq "$PATTERN"; then
    echo "❌ Commit $commit contains forbidden trailer: Co-authored-by: Cursor"
    git log -1 --oneline "$commit"
    FOUND=1
  fi
done < <(git rev-list "$RANGE" 2>/dev/null || git rev-list -n 1 HEAD)

if [[ "$FOUND" -eq 1 ]]; then
  echo
  echo "Remove any 'Co-authored-by: Cursor <…>' line from the commit message."
  echo "Do not rewrite published main history — fix on the feature branch only."
  exit 1
fi

echo "✅ No Cursor co-author trailer in checked commits."
exit 0
