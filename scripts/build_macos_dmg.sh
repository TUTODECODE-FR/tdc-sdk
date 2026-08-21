#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>
# Create TDC-Studio-macOS.dmg from Flutter release .app
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT/TDC-Studio-IDE-App"
RELEASE_DIR="$APP_DIR/build/macos/Build/Products/Release"
APP_NAME="TDC Studio.app"
OUT_DMG="$RELEASE_DIR/TDC-Studio-macOS.dmg"
STAGING="$RELEASE_DIR/dmg_staging"

if [[ ! -d "$RELEASE_DIR/$APP_NAME" ]]; then
  echo "❌ Missing $RELEASE_DIR/$APP_NAME — run flutter build macos --release first"
  exit 1
fi

rm -rf "$STAGING" "$OUT_DMG"
mkdir -p "$STAGING"
cp -R "$RELEASE_DIR/$APP_NAME" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

hdiutil create \
  -volname "TDC Studio" \
  -srcfolder "$STAGING" \
  -ov -format UDZO \
  "$OUT_DMG"

rm -rf "$STAGING"
echo "✅ DMG created: $OUT_DMG"
