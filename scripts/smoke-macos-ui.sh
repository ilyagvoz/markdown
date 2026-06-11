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

quit_app
rm -rf "$WATCH_DIR"

echo "UI smoke passed: file/folder open, shortcuts, current/workspace search, outline, folder watching, and crash checks."
