#!/usr/bin/env bash

SMOKE_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${ROOT_DIR:-$(cd "$SMOKE_LIB_DIR/../.." && pwd)}"
APP_PATH="${APP_PATH:-/Applications/Markdown.app}"
FIXTURE_DIR="${FIXTURE_DIR:-$ROOT_DIR/spikes/spike1-rendering-engine/fixtures}"
CRASH_DIR="${CRASH_DIR:-$HOME/Library/Logs/DiagnosticReports}"
MARKER="${MARKER:-$(mktemp /tmp/markdown-ui-smoke-marker.XXXXXX)}"
touch "$MARKER"

ensure_app_installed() {
  if [[ ! -x "$APP_PATH/Contents/MacOS/Markdown" ]]; then
    "$ROOT_DIR/scripts/build-macos-app.sh" >/dev/null
    "$ROOT_DIR/scripts/install-macos-app.sh" >/dev/null
  fi
}

announce_keyboard_smoke() {
  if [[ "${MARKDOWN_SMOKE_QUIET_NOTICE:-0}" == "1" ]]; then
    return
  fi
  echo $'\aUI smoke sends keyboard input. It will refocus Markdown before scripted keystrokes; avoid using the mouse until it finishes for the smoothest run.'
  osascript -e 'display notification "Smoke tests will refocus Markdown before scripted keystrokes." with title "Markdown UI smoke"' >/dev/null 2>&1 || true
}

quit_app() {
  osascript -e 'tell application "Markdown" to quit' >/dev/null 2>&1 || true
  sleep 0.5
  pkill -x Markdown >/dev/null 2>&1 || true
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
  local log_file="/tmp/markdown-ui-smoke-osa.$$.log"
  osascript <<APPLESCRIPT >"$log_file" 2>&1
on focusMarkdown(actionName)
  tell application "Markdown" to activate
  tell application "System Events"
    repeat 20 times
      if exists process "Markdown" then
        tell process "Markdown" to set frontmost to true
        set frontApp to name of first application process whose frontmost is true
        if frontApp is "Markdown" then return
      end if
      delay 0.1
    end repeat
    error "Markdown UI smoke could not focus Markdown before " & actionName & ". Keep the Markdown window available while smoke tests type."
  end tell
end focusMarkdown

on guardedKeystroke(textValue)
  my focusMarkdown("typing")
  tell application "System Events" to keystroke textValue
end guardedKeystroke

on guardedKeystrokeUsing(textValue, modifiers)
  my focusMarkdown("typing")
  tell application "System Events" to keystroke textValue using modifiers
end guardedKeystrokeUsing

on guardedKeyCode(codeValue)
  my focusMarkdown("key press")
  tell application "System Events" to key code codeValue
end guardedKeyCode

on guardedKeyCodeUsing(codeValue, modifiers)
  my focusMarkdown("key press")
  tell application "System Events" to key code codeValue using modifiers
end guardedKeyCodeUsing

on guardedClick(pointValue)
  my focusMarkdown("click")
  tell application "System Events" to click at pointValue
end guardedClick

tell application "Markdown" to activate
tell application "System Events"
  tell process "Markdown" to set frontmost to true
  delay 0.2
$script
end tell
APPLESCRIPT
  sleep 1
  if [[ -s "$log_file" ]]; then
    echo "AppleScript output for $label:"
    cat "$log_file"
  fi
  rm -f "$log_file"
  require_running "$label"
}
