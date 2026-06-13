#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT_DIR/scripts/lib/macos-ui-smoke.sh"

ensure_app_installed
announce_keyboard_smoke

echo "UI regression: folder new file"
NEW_FILE_DIR="$(mktemp -d /tmp/markdown-ui-new-file.XXXXXX)"
launch_app "$NEW_FILE_DIR"
run_applescript "create markdown file from folder view" '
  my guardedKeystrokeUsing("n", command down)
  delay 0.1
'
wait_for_path "$NEW_FILE_DIR/Untitled.md" "Untitled.md creation"
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
'
EXPECTED_NEW_FILE=$'From scratch\nSecond line'
wait_for_file_contents "$NEW_FILE_DIR/Untitled.md" "$EXPECTED_NEW_FILE" "new blank file autosave" 40 0.1
run_applescript "create second markdown file from folder view" '
  my guardedKeystrokeUsing("n", command down)
  delay 0.1
'
wait_for_path "$NEW_FILE_DIR/Untitled 2.md" "Untitled 2.md creation"

echo "UI regression: sidebar rename"
RENAME_DIR="$(mktemp -d /tmp/markdown-ui-rename.XXXXXX)"
RENAME_FILE="$RENAME_DIR/RenameMe.md"
printf 'Rename content\n' > "$RENAME_FILE"
open_item_in_running_app "$RENAME_DIR"
rm -rf "$NEW_FILE_DIR"
run_applescript "rename selected markdown file from sidebar" '
  tell process "Markdown"
    click menu item "Rename Selected File" of menu "File" of menu bar 1
  end tell
  delay 0.3
  my guardedKeystrokeUsing("a", command down)
  delay 0.1
  my guardedKeystroke("Renamed")
  my guardedKeyCode(36)
  delay 0.2
'
wait_for_path "$RENAME_DIR/Renamed.md" "renamed markdown file"
wait_for_no_path "$RENAME_FILE" "original rename file"
rm -rf "$RENAME_DIR"

quit_app
echo "UI regression passed: new file creation, blank-file autosave, and rename."
