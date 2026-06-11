#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT_DIR/scripts/lib/macos-ui-smoke.sh"

ensure_app_installed

echo "UI smoke: launch window placement"
launch_app "$FIXTURE_DIR/basic.md"

osascript <<'APPLESCRIPT'
tell application "System Events"
  tell process "Markdown"
    set windowPosition to position of window 1
    set windowSize to size of window 1
    return "Markdown window " & (item 1 of windowPosition as text) & " " & (item 2 of windowPosition as text) & " " & (item 1 of windowSize as text) & " " & (item 2 of windowSize as text)
  end tell
end tell
APPLESCRIPT

echo "UI smoke passed: launch window placement."
