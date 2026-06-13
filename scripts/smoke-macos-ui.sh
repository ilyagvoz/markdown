#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT_DIR/scripts/lib/macos-ui-smoke.sh"

ensure_app_installed
announce_keyboard_smoke

SMOKE_DIR="$(mktemp -d /tmp/markdown-ui-fast-smoke.XXXXXX)"
trap 'rm -rf "$SMOKE_DIR"' EXIT

SMOKE_FILE="$SMOKE_DIR/basic.md"
cat > "$SMOKE_FILE" <<'MARKDOWN'
# Smoke Guide

This section proves current-document search is alive.

## Section

Editable line
MARKDOWN

echo "UI smoke: single-file open, search, folder open, edit, create, rename"
launch_app "$SMOKE_FILE"
run_applescript "single-file current search" '
  my guardedKeystrokeUsing("f", command down)
  delay 0.2
  my guardedKeystroke("section")
  delay 0.3
  my guardedClick({610, 305})
  delay 0.2
  my guardedKeyCode(53)
'

open_item_in_running_app "$SMOKE_DIR"
run_applescript "create edit save and rename markdown file" '
  my guardedKeystrokeUsing("n", command down)
  delay 0.5
  tell process "Markdown"
    set targetArea to first text area of group "Markdown live preview editor" of group 1 of UI element 1 of scroll area 1 of group 1 of group 1 of group 1 of window 1 whose description contains "blank line 1"
    click targetArea
  end tell
  delay 0.2
  my guardedKeystroke("Smoke edit")
  my guardedKeystrokeUsing("s", command down)
  delay 0.2
  tell process "Markdown"
    click menu item "Rename Selected File" of menu "File" of menu bar 1
  end tell
  delay 0.2
  my guardedKeystrokeUsing("a", command down)
  delay 0.1
  my guardedKeystroke("SmokeRenamed")
  my guardedKeyCode(36)
'

RENAMED_FILE="$SMOKE_DIR/SmokeRenamed.md"
wait_for_path "$RENAMED_FILE" "renamed smoke file"
wait_for_no_path "$SMOKE_DIR/Untitled.md" "original smoke file"
wait_for_file_contents "$RENAMED_FILE" "Smoke edit" "renamed smoke file contents"

quit_app
echo "UI smoke passed: launch, single-file open, folder open, search, edit/save, new file, rename, and crash checks."
