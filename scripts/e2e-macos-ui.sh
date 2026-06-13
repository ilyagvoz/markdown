#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
export MARKER="${MARKER:-$(mktemp /tmp/markdown-ui-smoke-marker.XXXXXX)}"
touch "$MARKER"

echo $'\aMarkdown UI regression tests send keyboard input. They will refocus Markdown before scripted keystrokes; avoid using the mouse until they finish for the smoothest run.'
osascript -e 'display notification "UI regression tests will refocus Markdown before scripted keystrokes." with title "Markdown UI regression"' >/dev/null 2>&1 || true

export MARKDOWN_SMOKE_QUIET_NOTICE=1

"$ROOT_DIR/scripts/e2e-macos-navigation.sh"
"$ROOT_DIR/scripts/e2e-macos-files.sh"
"$ROOT_DIR/scripts/e2e-macos-editing.sh"
"$ROOT_DIR/scripts/e2e-macos-code-block-formatting.sh"
"$ROOT_DIR/scripts/e2e-macos-images.sh"
"$ROOT_DIR/scripts/e2e-macos-watch.sh"

echo "UI regression passed: file/folder open, shortcuts, current/workspace search, outline, new file creation, autosave, rename, live editing, formatting, image zoom, folder watching, selected-file churn, and crash checks."
