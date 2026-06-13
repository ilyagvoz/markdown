#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT_DIR/scripts/lib/macos-ui-smoke.sh"

ensure_app_installed
announce_keyboard_smoke

echo "UI regression: code block unlock and unwrap"
CODE_BLOCK_DIR="$(mktemp -d /tmp/markdown-ui-code-block.XXXXXX)"
CODE_BLOCK_FILE="$CODE_BLOCK_DIR/code-block.md"
SCREENSHOT_DIR="${MARKDOWN_SMOKE_SCREENSHOT_DIR:-$ROOT_DIR/artifacts/screenshots/code-block-formatting}"
mkdir -p "$SCREENSHOT_DIR"
cat > "$CODE_BLOCK_FILE" <<'MARKDOWN'
# Code Block

```swift
let value = 1
```
MARKDOWN

launch_app "$CODE_BLOCK_FILE"
run_applescript "unwrap fenced code block with left-arrow marker edit" '
  tell process "Markdown"
    set targetArea to first text area of group "Markdown live preview editor" of group 1 of UI element 1 of scroll area 1 of group 1 of group 1 of group 1 of window 1 whose description contains "code line"
    click targetArea
  end tell
  delay 0.2
  repeat 32 times
    my guardedKeyCode(123)
  end repeat
  delay 0.2
  my guardedKeyCode(51)
  delay 0.3
  my guardedKeystrokeUsing("s", command down)
  delay 0.8
'

EXPECTED_CODE_BLOCK=$'# Code Block\n\nlet value = 1'
if [[ "$(cat "$CODE_BLOCK_FILE")" != "$EXPECTED_CODE_BLOCK" ]]; then
  echo "Code-block unwrap regression failed: unexpected saved Markdown" >&2
  cat "$CODE_BLOCK_FILE" >&2
  exit 1
fi

EMPTY_CODE_FILE="$CODE_BLOCK_DIR/empty-code-line.md"
cat > "$EMPTY_CODE_FILE" <<'MARKDOWN'
# Delete Empty Code Line

```
alpha


beta
```
MARKDOWN

open_item_in_running_app "$EMPTY_CODE_FILE"
run_applescript "delete empty line inside fenced code block" '
  tell process "Markdown"
    set editorGroup to group "Markdown live preview editor" of group 1 of UI element 1 of scroll area 1 of group 1 of group 1 of group 1 of window 1
    set targetArea to first text area of editorGroup whose description contains "code line" and value is ""
    click targetArea
  end tell
  delay 0.2
  my guardedKeyCode(51)
  delay 0.4
  my guardedKeystrokeUsing("s", command down)
  delay 0.8
'

EXPECTED_EMPTY_CODE=$'# Delete Empty Code Line\n\n```\nalpha\n\nbeta\n```'
if [[ "$(cat "$EMPTY_CODE_FILE")" != "$EXPECTED_EMPTY_CODE" ]]; then
  echo "Empty code-line deletion regression failed: unexpected saved Markdown" >&2
  cat "$EMPTY_CODE_FILE" >&2
  exit 1
fi

SOURCE_SEGMENT_FILE="${MARKDOWN_CODE_BLOCK_SEGMENT_SOURCE:-$ROOT_DIR/scripts/fixtures/code-line-extraction.md}"
if [[ ! -f "$SOURCE_SEGMENT_FILE" ]]; then
      echo "Code-line extraction regression failed: missing source fixture at $SOURCE_SEGMENT_FILE" >&2
  exit 1
else
  SEGMENT_DIR="$(mktemp -d /tmp/markdown-ui-code-line-extract.XXXXXX)"
  SEGMENT_FILE="$SEGMENT_DIR/Test.md"
  cp "$SOURCE_SEGMENT_FILE" "$SEGMENT_FILE"
  python3 - "$SEGMENT_FILE" <<'PY'
import sys
from pathlib import Path

lines = Path(sys.argv[1]).read_text().splitlines()
for index, line in enumerate(lines):
    if line == "* dd a new line break here?":
        if index > 0 and index + 1 < len(lines) and lines[index - 1] != "```" and lines[index + 1] != "```":
            raise SystemExit(0)
print("Code-line extraction regression failed: fixture is not in pre-extraction fenced-code state", file=sys.stderr)
print(Path(sys.argv[1]).read_text(), file=sys.stderr)
raise SystemExit(1)
PY

  open_item_in_running_app "$SEGMENT_FILE"
  screencapture -x "$SCREENSHOT_DIR/code-line-extract-before.png" || true
  run_applescript "extract markdown-looking line from fenced code block" '
    tell process "Markdown"
      set editorGroup to group "Markdown live preview editor" of group 1 of UI element 1 of scroll area 1 of group 1 of group 1 of group 1 of window 1
      set targetArea to first text area of editorGroup whose description contains "code line" and value contains "* dd a new line break here?"
      click targetArea
    end tell
    delay 0.2
    my guardedKeyCodeUsing(123, command down)
    delay 0.2
    my guardedKeyCode(123)
    delay 0.5
    my guardedKeystrokeUsing("s", command down)
    delay 1
  '
  screencapture -x "$SCREENSHOT_DIR/code-line-extract-after.png" || true

  python3 - "$SEGMENT_FILE" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
lines = path.read_text().splitlines()
try:
    index = lines.index("Lets do a block segment, how do I a")
except ValueError:
    print("Code-line extraction regression failed: missing leading code line", file=sys.stderr)
    print(path.read_text(), file=sys.stderr)
    raise SystemExit(1)

checks = [
    (index - 1, "```", "opening fence before leading code line"),
    (index + 1, "```", "closing fence inserted before extracted list item"),
    (index + 2, "* dd a new line break here?", "extracted list item"),
    (index + 3, "```", "opening fence inserted after extracted list item"),
]
for line_index, expected, label in checks:
    if line_index < 0 or line_index >= len(lines) or lines[line_index] != expected:
        print(f"Code-line extraction regression failed: expected {label!s} at line {line_index + 1}", file=sys.stderr)
        print(path.read_text(), file=sys.stderr)
        raise SystemExit(1)

if index + 4 >= len(lines) or not lines[index + 4].startswith("how do I add a new line break here?"):
    print("Code-line extraction regression failed: trailing code line was not preserved after the new fence", file=sys.stderr)
    print(path.read_text(), file=sys.stderr)
    raise SystemExit(1)
PY

  rm -rf "$SEGMENT_DIR"
fi

rm -rf "$CODE_BLOCK_DIR"
echo "UI regression passed: code block unlock, unwrap, and single-line extraction."
