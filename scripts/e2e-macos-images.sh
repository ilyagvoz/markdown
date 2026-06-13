#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT_DIR/scripts/lib/macos-ui-smoke.sh"

ensure_app_installed
announce_keyboard_smoke

echo "UI regression: Markdown images and image zoom"
IMAGE_DIR="$(mktemp -d /tmp/markdown-ui-images.XXXXXX)"
IMAGE_FILE="$IMAGE_DIR/images.md"
IMAGE_ASSET="$IMAGE_DIR/tiny.svg"
IMAGE_FILE_URL="file://$IMAGE_ASSET"

cat > "$IMAGE_ASSET" <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" width="320" height="180" viewBox="0 0 320 180">
  <rect width="320" height="180" rx="16" fill="#fbfaf6"/>
  <rect x="18" y="18" width="284" height="144" rx="12" fill="#006b7a"/>
  <circle cx="96" cy="88" r="34" fill="#f1eee7"/>
  <path d="M142 128 188 76l30 34 22-24 44 42z" fill="#f1eee7"/>
</svg>
SVG

cat > "$IMAGE_FILE" <<MARKDOWN
# Image Test

![Tiny diagram](tiny.svg "Tiny title")

![File URL diagram]($IMAGE_FILE_URL)

After image
MARKDOWN

launch_app "$IMAGE_FILE"
run_applescript "open and zoom Markdown image" '
  tell process "Markdown"
    set editorGroup to group "Markdown live preview editor" of group 1 of UI element 1 of scroll area 1 of group 1 of group 1 of group 1 of window 1
    set imageGroup to first group of editorGroup whose description contains "image line"
    set imageFigure to first group of imageGroup whose role description is "figure"
    click first button of imageFigure whose description contains "Open image full screen"
  end tell
  delay 0.4
  my guardedKeystroke("=")
  delay 0.2
  my guardedKeystroke("-")
  delay 0.2
  my guardedKeystroke("0")
  delay 0.2
  my guardedKeyCode(53)
  delay 0.5
  my guardedKeystrokeUsing("s", command down)
  delay 0.8
'

EXPECTED_IMAGE=$'# Image Test\n\n![Tiny diagram](tiny.svg "Tiny title")\n\n![File URL diagram]('"$IMAGE_FILE_URL"$')\n\nAfter image'
if [[ "$(cat "$IMAGE_FILE")" != "$EXPECTED_IMAGE" ]]; then
  echo "Image regression failed: image Markdown changed unexpectedly" >&2
  cat "$IMAGE_FILE" >&2
  exit 1
fi

rm -rf "$IMAGE_DIR"
quit_app
echo "UI regression passed: Markdown image rendering and zoom controls."
