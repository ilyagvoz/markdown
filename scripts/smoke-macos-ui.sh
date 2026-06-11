#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
export MARKER="${MARKER:-$(mktemp /tmp/markdown-ui-smoke-marker.XXXXXX)}"
touch "$MARKER"

echo $'\aUI smoke sends keyboard input. It will refocus Markdown before scripted keystrokes; avoid using the mouse until it finishes for the smoothest run.'
osascript -e 'display notification "Smoke tests will refocus Markdown before scripted keystrokes." with title "Markdown UI smoke"' >/dev/null 2>&1 || true

export MARKDOWN_SMOKE_QUIET_NOTICE=1

"$ROOT_DIR/scripts/smoke-macos-navigation.sh"
"$ROOT_DIR/scripts/smoke-macos-files.sh"
"$ROOT_DIR/scripts/smoke-macos-editing.sh"
"$ROOT_DIR/scripts/smoke-macos-watch.sh"

echo "UI smoke passed: file/folder open, shortcuts, current/workspace search, outline, new file creation, autosave, rename, live editing, formatting, folder watching, selected-file churn, and crash checks."
