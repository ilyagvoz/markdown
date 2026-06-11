#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT_DIR/scripts/lib/macos-ui-smoke.sh"

ensure_app_installed
announce_keyboard_smoke

echo "UI smoke: folder watcher add/delete"
WATCH_DIR="$(mktemp -d /tmp/markdown-ui-watch.XXXXXX)"
mkdir -p "$WATCH_DIR/notes"
printf '# Alpha\n\nFirst file.\n' > "$WATCH_DIR/alpha.md"
printf '# Nested\n\nNested file.\n' > "$WATCH_DIR/notes/nested.md"
launch_app "$WATCH_DIR"
printf '# Added Later\n\nThis file should appear without reopening.\n' > "$WATCH_DIR/added-later.md"
sleep 2
require_running "folder watcher add"
rm -f "$WATCH_DIR/added-later.md"
sleep 2
require_running "folder watcher delete"
mv "$WATCH_DIR/notes/nested.md" "$WATCH_DIR/notes/renamed.md"
sleep 2
require_running "selected file rename"
rm -f "$WATCH_DIR/notes/renamed.md"
sleep 2
require_running "selected file delete"
rm -f "$WATCH_DIR/alpha.md"
sleep 2
require_running "last markdown file delete"

quit_app
rm -rf "$WATCH_DIR"

echo "UI smoke passed: folder watching and selected-file churn."
