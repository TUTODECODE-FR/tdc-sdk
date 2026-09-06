#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>
"""Seed GitLab issues from docs/VOLUNTEER_BOARD_ARCHIVED.md (optional).

Requires GITLAB_TOKEN (scope api). Idempotent: skips if an open issue already
has the same title prefix "[TDC-xxx]".

Usage:
  export GITLAB_TOKEN=glpat-…
  python3 scripts/seed_volunteer_issues.py
  python3 scripts/seed_volunteer_issues.py --dry-run
"""

from __future__ import annotations

import argparse
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request

PROJECT = os.environ.get("GITLAB_PROJECT", "tutodecode-org/tdc-sdk")
HOST = os.environ.get("GITLAB_HOST", "https://gitlab.com").rstrip("/")
ARCHIVED = os.path.join(
    os.path.dirname(__file__), "..", "docs", "VOLUNTEER_BOARD_ARCHIVED.md"
)


def api(method: str, path: str, token: str, data: bytes | None = None) -> object:
    url = f"{HOST}/api/v4{path}"
    req = urllib.request.Request(
        url,
        data=data,
        method=method,
        headers={
            "PRIVATE-TOKEN": token,
            "Accept": "application/json",
            "Content-Type": "application/json",
        },
    )
    with urllib.request.urlopen(req, timeout=30) as res:
        body = res.read().decode()
        if not body:
            return None
        import json

        return json.loads(body)


def parse_archived(path: str) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line.startswith("| TDC-"):
                continue
            parts = [p.strip() for p in line.strip("|").split("|")]
            if len(parts) < 4:
                continue
            rows.append(
                {
                    "id": parts[0],
                    "priority": parts[1],
                    "title": parts[2],
                    "description": parts[3],
                    "skills": parts[4] if len(parts) > 4 else "",
                }
            )
    return rows


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    token = os.environ.get("GITLAB_TOKEN", "").strip()
    if not token and not args.dry_run:
        print("GITLAB_TOKEN manquant — dry-run forcé.", file=sys.stderr)
        args.dry_run = True

    archived = os.path.normpath(ARCHIVED)
    if not os.path.isfile(archived):
        print(f"Fichier introuvable : {archived}", file=sys.stderr)
        return 1

    rows = parse_archived(archived)
    if not rows:
        print("Aucune ligne TDC-* trouvée.")
        return 0

    pid = urllib.parse.quote(PROJECT, safe="")
    existing_titles: set[str] = set()
    if token:
        try:
            issues = api(
                "GET",
                f"/projects/{pid}/issues?labels=benevolat&state=all&per_page=100",
                token,
            )
            if isinstance(issues, list):
                for issue in issues:
                    if isinstance(issue, dict):
                        existing_titles.add(str(issue.get("title", "")))
        except urllib.error.HTTPError as e:
            print(f"Avertissement liste issues : {e}", file=sys.stderr)

    import json

    created = 0
    for row in rows:
        title = f"[{row['id']}] {row['title']}"
        if any(title in t or row["id"] in t for t in existing_titles):
            print(f"skip  {title}")
            continue
        labels = ["benevolat", "wishlist", row["priority"]]
        desc = (
            f"{row['description']}\n\n"
            f"**Compétences** : {row['skills']}\n"
            f"**Origine** : wishlist archivée `{row['id']}`.\n"
        )
        payload = json.dumps(
            {"title": title, "description": desc, "labels": ",".join(labels)}
        ).encode()
        if args.dry_run:
            print(f"dry   {title}  labels={labels}")
            continue
        try:
            api("POST", f"/projects/{pid}/issues", token, data=payload)
            print(f"ok    {title}")
            created += 1
        except urllib.error.HTTPError as e:
            print(f"fail  {title}: {e.read().decode()[:200]}", file=sys.stderr)

    print(f"Done. Créées : {created}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
