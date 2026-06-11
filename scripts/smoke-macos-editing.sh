#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT_DIR/scripts/lib/macos-ui-smoke.sh"

ensure_app_installed
announce_keyboard_smoke

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
  my guardedKeystrokeUsing("a", command down)
  delay 0.1
  my guardedKeystroke("Here is a list with a bunch of bullet points:")
  my guardedKeyCode(36)
  my guardedKeystroke("* One")
  my guardedKeyCode(36)
  my guardedKeystroke("* Two")
  delay 1.0
  my guardedKeystrokeUsing("s", command down)
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
printf '1. One\n' > "$ORDERED_FILE"
launch_app "$ORDERED_FILE"
run_applescript "edit ordered list continuation" '
  tell process "Markdown"
    set targetArea to first text area of group "Markdown live preview editor" of group 1 of UI element 1 of scroll area 1 of group 1 of group 1 of group 1 of window 1 whose description contains "ordered-list line 1"
    click targetArea
  end tell
  delay 0.2
  repeat 8 times
    my guardedKeyCode(124)
  end repeat
  delay 0.1
  my guardedKeyCode(36)
  my guardedKeystroke("Two")
  my guardedKeyCode(36)
  my guardedKeystroke("Three")
  delay 1.0
  my guardedKeystrokeUsing("s", command down)
  delay 1
'
EXPECTED_ORDERED=$'1. One\n2. Two\n3. Three'
if [[ "$(cat "$ORDERED_FILE")" != "$EXPECTED_ORDERED" ]]; then
  echo "Ordered list smoke failed: unexpected saved Markdown" >&2
  cat "$ORDERED_FILE" >&2
  exit 1
fi
rm -rf "$ORDERED_DIR"

ORDERED_EXIT_DIR="$(mktemp -d /tmp/markdown-ui-ordered-exit.XXXXXX)"
ORDERED_EXIT_FILE="$ORDERED_EXIT_DIR/ordered-exit.md"
printf '1. One\n2. Two\n3. Three' > "$ORDERED_EXIT_FILE"
launch_app "$ORDERED_EXIT_FILE"
run_applescript "edit ordered list double-return exit" '
  tell process "Markdown"
    set targetArea to first text area of group "Markdown live preview editor" of group 1 of UI element 1 of scroll area 1 of group 1 of group 1 of group 1 of window 1 whose description contains "ordered-list line 3"
    click targetArea
  end tell
  delay 0.2
  repeat 8 times
    my guardedKeyCode(124)
  end repeat
  delay 0.1
  my guardedKeyCode(36)
  delay 0.2
  my guardedKeyCode(36)
  delay 0.2
  my guardedKeystroke("After list")
  delay 0.2
  my guardedKeyCode(36)
  delay 0.2
  my guardedKeystroke("Next paragraph")
  delay 1.0
  my guardedKeystrokeUsing("s", command down)
  delay 1
'
EXPECTED_ORDERED_EXIT=$'1. One\n2. Two\n3. Three\nAfter list\nNext paragraph'
if [[ "$(cat "$ORDERED_EXIT_FILE")" != "$EXPECTED_ORDERED_EXIT" ]]; then
  echo "Ordered list exit smoke failed: unexpected saved Markdown" >&2
  cat "$ORDERED_EXIT_FILE" >&2
  exit 1
fi
rm -rf "$ORDERED_EXIT_DIR"

BLANK_ENTER_DIR="$(mktemp -d /tmp/markdown-ui-blank-enter.XXXXXX)"
BLANK_ENTER_FILE="$BLANK_ENTER_DIR/blank-enter.md"
printf 'Intro\n' > "$BLANK_ENTER_FILE"
launch_app "$BLANK_ENTER_FILE"
run_applescript "edit blank line then press return" '
  tell process "Markdown"
    set targetArea to first text area of group "Markdown live preview editor" of group 1 of UI element 1 of scroll area 1 of group 1 of group 1 of group 1 of window 1 whose description contains "blank line"
    click targetArea
  end tell
  delay 0.2
  my guardedKeystroke("This paragraph should survive Return")
  my guardedKeyCode(36)
  my guardedKeystroke("Next paragraph")
  delay 1.0
  my guardedKeystrokeUsing("s", command down)
  delay 0.7
'
EXPECTED_BLANK_ENTER=$'Intro\nThis paragraph should survive Return\nNext paragraph'
if [[ "$(cat "$BLANK_ENTER_FILE")" != "$EXPECTED_BLANK_ENTER" ]]; then
  echo "Blank-line Return smoke failed: unexpected saved Markdown" >&2
  cat "$BLANK_ENTER_FILE" >&2
  exit 1
fi
rm -rf "$BLANK_ENTER_DIR"

BLANK_BLUR_DIR="$(mktemp -d /tmp/markdown-ui-blank-blur.XXXXXX)"
BLANK_BLUR_FILE="$BLANK_BLUR_DIR/blank-blur.md"
printf 'Intro\n' > "$BLANK_BLUR_FILE"
launch_app "$BLANK_BLUR_FILE"
run_applescript "edit blank line then blur" '
  tell process "Markdown"
    set targetArea to first text area of group "Markdown live preview editor" of group 1 of UI element 1 of scroll area 1 of group 1 of group 1 of group 1 of window 1 whose description contains "blank line"
    click targetArea
  end tell
  delay 0.2
  my guardedKeystroke("This paragraph should survive blur")
  delay 0.2
  my guardedClick({610, 150})
  delay 2.2
'
EXPECTED_BLANK_BLUR=$'Intro\nThis paragraph should survive blur'
if [[ "$(cat "$BLANK_BLUR_FILE")" != "$EXPECTED_BLANK_BLUR" ]]; then
  echo "Blank-line blur/autosave smoke failed: unexpected Markdown" >&2
  cat "$BLANK_BLUR_FILE" >&2
  exit 1
fi
rm -rf "$BLANK_BLUR_DIR"

COPY_DIR="$(mktemp -d /tmp/markdown-ui-copy.XXXXXX)"
COPY_FILE="$COPY_DIR/copy.md"
EXPECTED_COPY_DOCUMENT=$'# Copy Test\n\nSome **markdown**\n\n```swift\nlet value = 42\nprint(value)\n```\n\nAfter code'
EXPECTED_COPY_CODE=$'```swift\nlet value = 42\nprint(value)\n```'
printf '%s' "$EXPECTED_COPY_DOCUMENT" > "$COPY_FILE"
launch_app "$COPY_FILE"
printf '' | pbcopy
run_applescript "copy whole document as markdown" '
  tell process "Markdown"
    set htmlContent to first UI element of scroll area 1 of group 1 of group 1 of group 1 of window 1 whose role description is "HTML content"
    click first button of htmlContent whose description is "Copy document as Markdown"
  end tell
  delay 0.5
'
if [[ "$(pbpaste)" != "$EXPECTED_COPY_DOCUMENT" ]]; then
  echo "Document copy smoke failed: unexpected clipboard Markdown" >&2
  pbpaste >&2
  exit 1
fi
printf '' | pbcopy
run_applescript "copy code section as markdown" '
  tell process "Markdown"
    set editorGroup to group "Markdown live preview editor" of group 1 of UI element 1 of scroll area 1 of group 1 of group 1 of group 1 of window 1
    click first button of editorGroup whose description contains "Copy code section"
  end tell
  delay 0.5
'
if [[ "$(pbpaste)" != "$EXPECTED_COPY_CODE" ]]; then
  echo "Code-section copy smoke failed: unexpected clipboard Markdown" >&2
  pbpaste >&2
  exit 1
fi
rm -rf "$COPY_DIR"

FORMAT_DIR="$(mktemp -d /tmp/markdown-ui-format.XXXXXX)"
FORMAT_FILE="$FORMAT_DIR/format.md"
printf 'Format me\n' > "$FORMAT_FILE"
launch_app "$FORMAT_FILE"
run_applescript "format selected text bold" '
  tell process "Markdown"
    set targetArea to first text area of group "Markdown live preview editor" of group 1 of UI element 1 of scroll area 1 of group 1 of group 1 of group 1 of window 1 whose description contains "paragraph line 1"
    click targetArea
  end tell
  delay 0.2
  my guardedKeystrokeUsing("a", command down)
  delay 0.2
  my guardedKeystrokeUsing("b", command down)
  delay 0.3
  my guardedKeystrokeUsing("s", command down)
  delay 0.7
'
if [[ "$(cat "$FORMAT_FILE")" != "**Format me**" ]]; then
  echo "Bold formatting smoke failed: unexpected saved Markdown" >&2
  cat "$FORMAT_FILE" >&2
  exit 1
fi
HIGHLIGHT_FILE="$FORMAT_DIR/highlight.md"
printf 'Highlight me\n' > "$HIGHLIGHT_FILE"
launch_app "$HIGHLIGHT_FILE"
run_applescript "format selected text highlight" '
  tell process "Markdown"
    set targetArea to first text area of group "Markdown live preview editor" of group 1 of UI element 1 of scroll area 1 of group 1 of group 1 of group 1 of window 1 whose description contains "paragraph line 1"
    click targetArea
  end tell
  delay 0.2
  my guardedKeystrokeUsing("a", command down)
  delay 0.2
  my guardedKeystrokeUsing("h", {command down, control down})
  delay 0.3
  my guardedKeystrokeUsing("s", command down)
  delay 0.7
'
if [[ "$(cat "$HIGHLIGHT_FILE")" != "<mark>Highlight me</mark>" ]]; then
  echo "Highlight formatting smoke failed: unexpected saved Markdown" >&2
  cat "$HIGHLIGHT_FILE" >&2
  exit 1
fi
CODE_FILE="$FORMAT_DIR/code.md"
printf 'Code me\n' > "$CODE_FILE"
launch_app "$CODE_FILE"
run_applescript "format selected text inline code" '
  tell process "Markdown"
    set targetArea to first text area of group "Markdown live preview editor" of group 1 of UI element 1 of scroll area 1 of group 1 of group 1 of group 1 of window 1 whose description contains "paragraph line 1"
    click targetArea
  end tell
  delay 0.2
  my guardedKeystrokeUsing("a", command down)
  delay 0.2
  my guardedKeystrokeUsing("e", command down)
  delay 0.3
  my guardedKeystrokeUsing("s", command down)
  delay 0.7
'
if [[ "$(cat "$CODE_FILE")" != '`Code me`' ]]; then
  echo "Inline code formatting smoke failed: unexpected saved Markdown" >&2
  cat "$CODE_FILE" >&2
  exit 1
fi
LINK_FILE="$FORMAT_DIR/link.md"
printf 'OpenAI\n' > "$LINK_FILE"
launch_app "$LINK_FILE"
run_applescript "format selected text link" '
  tell process "Markdown"
    set targetArea to first text area of group "Markdown live preview editor" of group 1 of UI element 1 of scroll area 1 of group 1 of group 1 of group 1 of window 1 whose description contains "paragraph line 1"
    click targetArea
  end tell
  delay 0.2
  my guardedKeystrokeUsing("a", command down)
  delay 0.2
  my guardedKeystrokeUsing("k", command down)
  delay 0.2
  my guardedKeystroke("https://openai.com")
  delay 0.3
  my guardedKeystrokeUsing("s", command down)
  delay 0.7
'
if [[ "$(cat "$LINK_FILE")" != '[OpenAI](https://openai.com)' ]]; then
  echo "Link formatting smoke failed: unexpected saved Markdown" >&2
  cat "$LINK_FILE" >&2
  exit 1
fi
rm -rf "$FORMAT_DIR"

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
  my guardedKeystrokeUsing("a", command down)
  delay 0.1
  my guardedKeystroke("Changed")
  delay 0.2
  my guardedKeystrokeUsing("z", command down)
  delay 0.5
  my guardedKeystrokeUsing("s", command down)
  delay 0.7
'
if [[ "$(cat "$UNDO_FILE")" != "Original" ]]; then
  echo "Undo smoke failed: unexpected saved Markdown after undo" >&2
  cat "$UNDO_FILE" >&2
  exit 1
fi
run_applescript "redo edit" '
  my guardedKeystrokeUsing("z", {command down, shift down})
  delay 0.5
  my guardedKeystrokeUsing("s", command down)
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
    my guardedKeyCode(123)
  end repeat
  delay 0.2
  my guardedKeystroke(">")
  delay 1.0
  my guardedKeystrokeUsing("s", command down)
  delay 1
'
if [[ "$(cat "$MARKER_FILE")" != "> One" ]]; then
  echo "Marker editing smoke failed: unexpected saved Markdown" >&2
  cat "$MARKER_FILE" >&2
  exit 1
fi
rm -rf "$MARKER_DIR"

quit_app
echo "UI smoke passed: live editing, autosave regressions, formatting, undo/redo, and marker replacement."
