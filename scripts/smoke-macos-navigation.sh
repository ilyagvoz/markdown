#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT_DIR/scripts/lib/macos-ui-smoke.sh"

ensure_app_installed
announce_keyboard_smoke

echo "UI smoke: Finder-style file open"
launch_app_from_finder_item "$FIXTURE_DIR/basic.md"
FINDER_SELECTED_PATH="$(osascript -l JavaScript <<JXA
ObjC.import('Foundation')
var defaults = $.NSUserDefaults.alloc.initWithSuiteName('$BUNDLE_ID')
var data = defaults.dataForKey('Markdown.RestoredAppState.v1')
var result = ''
if (data) {
  var stateJSON = ObjC.unwrap($.NSString.alloc.initWithDataEncoding(data, $.NSUTF8StringEncoding))
  result = JSON.parse(stateJSON).selectedFilePath || ''
}
result
JXA
)"
if [[ "$FINDER_SELECTED_PATH" != "$FIXTURE_DIR/basic.md" ]]; then
  echo "Finder-style open failed: expected $FIXTURE_DIR/basic.md, got ${FINDER_SELECTED_PATH:-<empty>}" >&2
  exit 1
fi

echo "UI smoke: single-file open and shortcuts"
launch_app "$FIXTURE_DIR/basic.md"
run_applescript "single-file search" '
  my guardedKeystrokeUsing("f", command down)
  delay 0.3
  my guardedKeystroke("section")
  delay 0.3
  my guardedClick({610, 305})
'
run_applescript "shortcut help" '
  my guardedKeystrokeUsing("/", command down)
  delay 0.4
  my guardedKeyCode(53)
'
run_applescript "pane toggles from single file" '
  my guardedKeyCodeUsing(124, command down)
  delay 0.2
  my guardedKeyCodeUsing(124, command down)
  delay 0.2
  my guardedKeyCodeUsing(123, command down)
  delay 0.2
  my guardedKeyCodeUsing(123, command down)
'
run_applescript "open panel shortcut" '
  my guardedKeystrokeUsing("o", command down)
  delay 0.5
  my guardedKeyCode(53)
'

echo "UI smoke: folder open, navigation, search, outline"
launch_app "$FIXTURE_DIR"
run_applescript "sidebar plain-key navigation" '
  my guardedKeyCode(126)
  delay 0.2
  my guardedKeyCode(49)
  delay 0.2
  my guardedKeyCode(49)
  delay 0.2
  my guardedKeyCode(125)
  delay 0.2
  my guardedKeyCode(125)
  delay 0.2
  my guardedKeyCode(36)
'
run_applescript "folder navigation shortcuts" '
  my guardedKeyCodeUsing(125, command down)
  delay 0.2
  my guardedKeyCodeUsing(125, command down)
  delay 0.2
  my guardedKeyCodeUsing(126, command down)
'
run_applescript "folder search and outline jump" '
  my guardedKeystrokeUsing("f", command down)
  delay 0.3
  my guardedKeystroke("markdown")
  delay 0.3
  my guardedClick({610, 305})
  delay 0.3
  my guardedClick({1130, 382})
'
run_applescript "workspace search result jump" '
  my guardedKeystrokeUsing("f", command down)
  delay 0.2
  my guardedKeystrokeUsing("a", command down)
  delay 0.1
  my guardedKeystroke("swift")
  delay 1.0
  my guardedClick({620, 405})
'
run_applescript "reveal selected file shortcut" '
  my guardedKeystrokeUsing("r", command down)
  delay 0.5
'

quit_app
echo "UI smoke passed: navigation, search, outline, pane toggles, reveal, and open shortcuts."
