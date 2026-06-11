#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_PATH="${APP_PATH:-/Applications/Markdown.app}"
FIXTURE_DIR="$ROOT_DIR/spikes/spike1-rendering-engine/fixtures"
CRASH_DIR="$HOME/Library/Logs/DiagnosticReports"
MARKER="$(mktemp /tmp/markdown-ui-smoke-marker.XXXXXX)"
touch "$MARKER"

if [[ ! -x "$APP_PATH/Contents/MacOS/Markdown" ]]; then
  "$ROOT_DIR/scripts/build-macos-app.sh" >/dev/null
  "$ROOT_DIR/scripts/install-macos-app.sh" >/dev/null
fi

quit_app() {
  osascript -e 'tell application "Markdown" to quit' >/dev/null 2>&1 || true
  sleep 1
}

launch_app() {
  local open_path="$1"
  quit_app
  open -n "$APP_PATH" --args --open "$open_path"
  sleep 3
  require_running "launching $open_path"
  focus_window
}

focus_window() {
  osascript <<'APPLESCRIPT' >/dev/null
tell application "Markdown" to activate
tell application "System Events"
  tell process "Markdown"
    set frontmost to true
    set position of window 1 to {40, 70}
    set size of window 1 to {1320, 820}
  end tell
end tell
APPLESCRIPT
  sleep 0.4
}

require_running() {
  local label="$1"
  if ! pgrep -x Markdown >/dev/null; then
    echo "Markdown exited during UI smoke: $label" >&2
    exit 1
  fi
  check_no_crash_reports "$label"
}

check_no_crash_reports() {
  local label="$1"
  if find "$CRASH_DIR" -name 'Markdown-*.ips' -newer "$MARKER" -print -quit | grep -q .; then
    echo "New Markdown crash report appeared during UI smoke: $label" >&2
    find "$CRASH_DIR" -name 'Markdown-*.ips' -newer "$MARKER" -print >&2
    exit 1
  fi
}

run_applescript() {
  local label="$1"
  local script="$2"
  osascript <<APPLESCRIPT >/tmp/markdown-ui-smoke-osa.log 2>&1
tell application "Markdown" to activate
tell application "System Events"
  tell process "Markdown" to set frontmost to true
  delay 0.2
$script
end tell
APPLESCRIPT
  sleep 1
  if [[ -s /tmp/markdown-ui-smoke-osa.log ]]; then
    echo "AppleScript output for $label:"
    cat /tmp/markdown-ui-smoke-osa.log
  fi
  require_running "$label"
}

echo "UI smoke: single-file open and shortcuts"
launch_app "$FIXTURE_DIR/basic.md"
run_applescript "single-file search" '
  keystroke "f" using command down
  delay 0.3
  keystroke "section"
  delay 0.3
  click at {610, 305}
'
run_applescript "shortcut help" '
  keystroke "/" using command down
  delay 0.4
  key code 53
'
run_applescript "pane toggles from single file" '
  key code 124 using command down
  delay 0.2
  key code 124 using command down
  delay 0.2
  key code 123 using command down
  delay 0.2
  key code 123 using command down
'
run_applescript "open panel shortcut" '
  keystroke "o" using command down
  delay 0.5
  key code 53
'

echo "UI smoke: folder open, navigation, search, outline"
launch_app "$FIXTURE_DIR"
run_applescript "sidebar plain-key navigation" '
  key code 126
  delay 0.2
  key code 49
  delay 0.2
  key code 49
  delay 0.2
  key code 125
  delay 0.2
  key code 125
  delay 0.2
  key code 36
'
run_applescript "folder navigation shortcuts" '
  key code 125 using command down
  delay 0.2
  key code 125 using command down
  delay 0.2
  key code 126 using command down
'
run_applescript "folder search and outline jump" '
  keystroke "f" using command down
  delay 0.3
  keystroke "markdown"
  delay 0.3
  click at {610, 305}
  delay 0.3
  click at {1130, 382}
'
run_applescript "workspace search result jump" '
  keystroke "f" using command down
  delay 0.2
  keystroke "a" using command down
  delay 0.1
  keystroke "swift"
  delay 1.0
  click at {620, 405}
'
run_applescript "reveal selected file shortcut" '
  keystroke "r" using command down
  delay 0.5
'

echo "UI smoke: live preview editing"
EDIT_DIR="$(mktemp -d /tmp/markdown-ui-edit.XXXXXX)"
EDIT_FILE="$EDIT_DIR/edit.md"
printf 'Hello\n' > "$EDIT_FILE"
launch_app "$EDIT_FILE"
run_applescript "edit new bullet content" '
  tell process "Markdown"
    set targetArea to first text area of group "Markdown live preview editor" of group 1 of UI element 1 of scroll area 1 of group 1 of group 1 of group 1 of window 1 whose description contains "paragraph line 1"
    click targetArea
  end tell
  delay 0.2
  keystroke "a" using command down
  delay 0.1
  keystroke "Here is a list with a bunch of bullet points:"
  key code 36
  keystroke "* One"
  key code 36
  keystroke "* Two"
  delay 1.0
  keystroke "s" using command down
  delay 1
'
EXPECTED_EDIT=$'Here is a list with a bunch of bullet points:\n* One\n* Two'
if [[ "$(cat "$EDIT_FILE")" != "$EXPECTED_EDIT" ]]; then
  echo "Live editing smoke failed: unexpected saved Markdown" >&2
  cat "$EDIT_FILE" >&2
  exit 1
fi
rm -rf "$EDIT_DIR"

ORDERED_DIR="$(mktemp -d /tmp/markdown-ui-ordered.XXXXXX)"
ORDERED_FILE="$ORDERED_DIR/ordered.md"
printf 'Hello\n' > "$ORDERED_FILE"
launch_app "$ORDERED_FILE"
run_applescript "edit ordered list continuation" '
  tell process "Markdown"
    set targetArea to first text area of group "Markdown live preview editor" of group 1 of UI element 1 of scroll area 1 of group 1 of group 1 of group 1 of window 1 whose description contains "paragraph line 1"
    click targetArea
  end tell
  delay 0.2
  keystroke "a" using command down
  delay 0.1
  keystroke "Steps:"
  key code 36
  keystroke "1. One"
  key code 36
  keystroke "Two"
  key code 36
  keystroke "Three"
  delay 1.0
  keystroke "s" using command down
  delay 1
'
EXPECTED_ORDERED=$'Steps:\n1. One\n2. Two\n3. Three'
if [[ "$(cat "$ORDERED_FILE")" != "$EXPECTED_ORDERED" ]]; then
  echo "Ordered list smoke failed: unexpected saved Markdown" >&2
  cat "$ORDERED_FILE" >&2
  exit 1
fi
rm -rf "$ORDERED_DIR"

UNDO_DIR="$(mktemp -d /tmp/markdown-ui-undo.XXXXXX)"
UNDO_FILE="$UNDO_DIR/undo.md"
printf 'Original\n' > "$UNDO_FILE"
launch_app "$UNDO_FILE"
run_applescript "edit undo and redo" '
  tell process "Markdown"
    set targetArea to first text area of group "Markdown live preview editor" of group 1 of UI element 1 of scroll area 1 of group 1 of group 1 of group 1 of window 1 whose description contains "paragraph line 1"
    click targetArea
  end tell
  delay 0.2
  keystroke "a" using command down
  delay 0.1
  keystroke "Changed"
  delay 0.2
  keystroke "z" using command down
  delay 0.5
  keystroke "s" using command down
  delay 0.7
'
if [[ "$(cat "$UNDO_FILE")" != "Original" ]]; then
  echo "Undo smoke failed: unexpected saved Markdown after undo" >&2
  cat "$UNDO_FILE" >&2
  exit 1
fi
run_applescript "redo edit" '
  keystroke "z" using {command down, shift down}
  delay 0.5
  keystroke "s" using command down
  delay 0.7
'
if [[ "$(cat "$UNDO_FILE")" != "Changed" ]]; then
  echo "Redo smoke failed: unexpected saved Markdown after redo" >&2
  cat "$UNDO_FILE" >&2
  exit 1
fi
rm -rf "$UNDO_DIR"

MARKER_DIR="$(mktemp -d /tmp/markdown-ui-marker.XXXXXX)"
MARKER_FILE="$MARKER_DIR/marker.md"
printf '* One\n' > "$MARKER_FILE"
launch_app "$MARKER_FILE"
run_applescript "edit marker replacement" '
  tell process "Markdown"
    set targetArea to first text area of group "Markdown live preview editor" of group 1 of UI element 1 of scroll area 1 of group 1 of group 1 of group 1 of window 1 whose description contains "unordered-list line 1"
    click targetArea
  end tell
  delay 0.2
  repeat 8 times
    key code 123
  end repeat
  delay 0.2
  keystroke ">"
  delay 1.0
  keystroke "s" using command down
  delay 1
'
if [[ "$(cat "$MARKER_FILE")" != "> One" ]]; then
  echo "Marker editing smoke failed: unexpected saved Markdown" >&2
  cat "$MARKER_FILE" >&2
  exit 1
fi
rm -rf "$MARKER_DIR"

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

echo "UI smoke passed: file/folder open, shortcuts, current/workspace search, outline, live editing, folder watching, selected-file churn, and crash checks."
