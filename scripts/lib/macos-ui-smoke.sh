#!/usr/bin/env bash

SMOKE_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${ROOT_DIR:-$(cd "$SMOKE_LIB_DIR/../.." && pwd)}"
APP_PATH="${APP_PATH:-/Applications/Markdown.app}"
BUNDLE_ID="${BUNDLE_ID:-com.gvozdenko.markdown}"
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
  if pgrep -x Markdown >/dev/null; then
    osascript -e "tell application id \"$BUNDLE_ID\" to quit" >/dev/null 2>&1 || true
  fi
  sleep 0.5
  pkill -f "$APP_PATH/Contents/MacOS/Markdown" >/dev/null 2>&1 || true
  pkill -x Markdown >/dev/null 2>&1 || true
  sleep 1
}

launch_app() {
  local open_path="$1"
  local frame
  quit_app
  prepare_smoke_window_placement
  frame="$(smoke_window_frame_default)"
  open -n -j "$APP_PATH" --args --smoke-window-frame-default "$frame" --open "$open_path"
  sleep 3
  require_running "launching $open_path"
  focus_window
}

launch_app_from_finder_item() {
  local open_path="$1"
  quit_app
  prepare_smoke_window_placement
  open -n -b "$BUNDLE_ID" "$open_path"
  sleep 3
  require_running "opening Finder item $open_path"
  focus_window
}

smoke_window_bounds() {
  if [[ -n "${MARKDOWN_SMOKE_WINDOW_BOUNDS:-}" ]]; then
    tr ',' ' ' <<<"$MARKDOWN_SMOKE_WINDOW_BOUNDS"
    return
  fi

  osascript -l JavaScript <<'JXA'
ObjC.import('AppKit')

var screens = $.NSScreen.screens
var target = $.NSScreen.mainScreen

for (var index = 0; index < screens.count; index += 1) {
  var screen = screens.objectAtIndex(index)
  var name = screen.localizedName ? ObjC.unwrap(screen.localizedName) : ''
  if (/built[- ]?in|retina|macbook|color lcd/i.test(name)) {
    target = screen
    break
  }
}

var frame = target.frame
var visible = target.visibleFrame
var left = Math.round(visible.origin.x)
var top = Math.round((frame.origin.y + frame.size.height) - (visible.origin.y + visible.size.height))
var targetWidth = Math.round(visible.size.width)
var targetHeight = Math.round(visible.size.height)

String(left) + ' ' + String(top) + ' ' + String(targetWidth) + ' ' + String(targetHeight)
JXA
}

smoke_window_frame_default() {
  if [[ -n "${MARKDOWN_SMOKE_WINDOW_FRAME_DEFAULT:-}" ]]; then
    printf '%s\n' "$MARKDOWN_SMOKE_WINDOW_FRAME_DEFAULT"
    return
  fi

  osascript -l JavaScript <<'JXA'
ObjC.import('AppKit')

var screens = $.NSScreen.screens
var target = $.NSScreen.mainScreen

for (var index = 0; index < screens.count; index += 1) {
  var screen = screens.objectAtIndex(index)
  var name = screen.localizedName ? ObjC.unwrap(screen.localizedName) : ''
  if (/built[- ]?in|retina|macbook|color lcd/i.test(name)) {
    target = screen
    break
  }
}

var frame = target.frame
var visible = target.visibleFrame
var left = Math.round(visible.origin.x)
var bottom = Math.round(visible.origin.y)
var targetWidth = Math.round(visible.size.width)
var targetHeight = Math.round(visible.size.height)
var screenLeft = Math.round(frame.origin.x)
var screenBottom = Math.round(visible.origin.y)
var screenWidth = Math.round(frame.size.width)
var screenHeight = Math.round(visible.size.height)

String(left) + ' ' + String(bottom) + ' ' + String(targetWidth) + ' ' + String(targetHeight) + ' ' + String(screenLeft) + ' ' + String(screenBottom) + ' ' + String(screenWidth) + ' ' + String(screenHeight) + ' '
JXA
}

prepare_smoke_window_placement() {
  local frame key keys
  frame="$(smoke_window_frame_default)"
  keys="$(defaults read "$BUNDLE_ID" 2>/dev/null | sed -n 's/^    "\(NSWindow Frame .*AppWindow-1\)" = .*/\1/p' || true)"

  if [[ -z "$keys" ]]; then
    keys=$'NSWindow Frame SwiftUI.ModifiedContent<SwiftUI.ModifiedContent<MarkdownApp.ContentView, SwiftUI._EnvironmentKeyWritingModifier<Swift.Optional<MarkdownApp.AppModel>>>, SwiftUI._TaskModifier2>-1-AppWindow-1\nNSWindow Frame SwiftUI.ModifiedContent<SwiftUI.ModifiedContent<SwiftUI.ModifiedContent<MarkdownApp.ContentView, SwiftUI._EnvironmentKeyWritingModifier<Swift.Optional<MarkdownApp.AppModel>>>, SwiftUI._PreferenceWritingModifier<SwiftUI.PreferredColorSchemeKey>>, SwiftUI._TaskModifier2>-1-AppWindow-1'
  fi

  while IFS= read -r key; do
    [[ -n "$key" ]] || continue
    defaults write "$BUNDLE_ID" "$key" "$frame"
  done <<<"$keys"
}

focus_window() {
  local left top width height
  read -r left top width height <<<"$(smoke_window_bounds)"

  osascript <<APPLESCRIPT >/dev/null
tell application "System Events"
  repeat 40 times
    if exists process "Markdown" then
      tell process "Markdown"
        if exists window 1 then
          set position of window 1 to {$left, $top}
          set size of window 1 to {$width, $height}
          exit repeat
        end if
      end tell
    end if
    delay 0.05
  end repeat
end tell
tell application "Markdown" to activate
tell application "System Events" to tell process "Markdown" to set frontmost to true
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
