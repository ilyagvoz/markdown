#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT_DIR/scripts/lib/macos-ui-smoke.sh"

ensure_app_installed
announce_keyboard_smoke

echo "UI smoke: folder new file"
NEW_FILE_DIR="$(mktemp -d /tmp/markdown-ui-new-file.XXXXXX)"
launch_app "$NEW_FILE_DIR"
run_applescript "create markdown file from folder view" '
  my guardedKeystrokeUsing("n", command down)
  delay 1.0
'
if [[ ! -f "$NEW_FILE_DIR/Untitled.md" ]]; then
  echo "New file smoke failed: Untitled.md was not created" >&2
  find "$NEW_FILE_DIR" -maxdepth 1 -print >&2
  exit 1
fi
run_applescript "edit newly created blank markdown file with autosave" '
  tell process "Markdown"
    set targetArea to first text area of group "Markdown live preview editor" of group 1 of UI element 1 of scroll area 1 of group 1 of group 1 of group 1 of window 1 whose description contains "blank line 1"
    set targetSize to size of targetArea
    if item 2 of targetSize < 300 then error "Blank document text area was not tall enough to click comfortably."
    click targetArea
  end tell
  delay 0.2
  my guardedKeystroke("From scratch")
  my guardedKeyCode(36)
  my guardedKeystroke("Second line")
  delay 2.2
'
EXPECTED_NEW_FILE=$'From scratch\nSecond line'
if [[ "$(cat "$NEW_FILE_DIR/Untitled.md")" != "$EXPECTED_NEW_FILE" ]]; then
  echo "New blank file editing/autosave smoke failed: unexpected Markdown" >&2
  cat "$NEW_FILE_DIR/Untitled.md" >&2
  exit 1
fi
run_applescript "create second markdown file from folder view" '
  my guardedKeystrokeUsing("n", command down)
  delay 1.0
'
if [[ ! -f "$NEW_FILE_DIR/Untitled 2.md" ]]; then
  echo "New file smoke failed: Untitled 2.md was not created" >&2
  find "$NEW_FILE_DIR" -maxdepth 1 -print >&2
  exit 1
fi
rm -rf "$NEW_FILE_DIR"

echo "UI smoke: sidebar rename"
RENAME_DIR="$(mktemp -d /tmp/markdown-ui-rename.XXXXXX)"
RENAME_FILE="$RENAME_DIR/RenameMe.md"
printf 'Rename content\n' > "$RENAME_FILE"
launch_app "$RENAME_DIR"
run_applescript "rename selected markdown file from sidebar" '
  tell process "Markdown"
    click menu item "Rename Selected File" of menu "File" of menu bar 1
  end tell
  delay 0.3
  my guardedKeystrokeUsing("a", command down)
  delay 0.1
  my guardedKeystroke("Renamed")
  my guardedKeyCode(36)
  delay 1.0
'
if [[ ! -f "$RENAME_DIR/Renamed.md" || -f "$RENAME_FILE" ]]; then
  echo "Sidebar rename smoke failed: expected Renamed.md only" >&2
  find "$RENAME_DIR" -maxdepth 1 -print >&2
  exit 1
fi
rm -rf "$RENAME_DIR"

quit_app
echo "UI smoke passed: new file creation, blank-file autosave, and rename."
