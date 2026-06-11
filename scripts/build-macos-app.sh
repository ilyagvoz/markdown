#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PACKAGE_DIR="$ROOT_DIR/apps/macos/Markdown"
APP_DIR="$ROOT_DIR/artifacts/Markdown.app"
CONFIGURATION="${CONFIGURATION:-release}"

source "$ROOT_DIR/scripts/lib/swift-env.sh"

cd "$PACKAGE_DIR"
swift build \
  --disable-sandbox \
  --cache-path "$MARKDOWN_SWIFT_CACHE_PATH" \
  --scratch-path "$MARKDOWN_SWIFT_SCRATCH_PATH" \
  --manifest-cache local \
  -c "$CONFIGURATION"

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$PACKAGE_DIR/.build/$CONFIGURATION/Markdown" "$APP_DIR/Contents/MacOS/Markdown"
cp "$PACKAGE_DIR/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"
find "$PACKAGE_DIR/Resources" -maxdepth 1 -type f ! -name "Info.plist" -exec cp {} "$APP_DIR/Contents/Resources/" \;
codesign --force --deep --sign - "$APP_DIR"

echo "$APP_DIR"
