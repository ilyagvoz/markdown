#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_SOURCE="$ROOT_DIR/artifacts/Markdown.app"
APP_DEST="/Applications/Markdown.app"

"$ROOT_DIR/scripts/build-macos-app.sh" >/dev/null

rm -rf "$APP_DEST"
ditto "$APP_SOURCE" "$APP_DEST"

echo "$APP_DEST"
