#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT_DIR/scripts/lib/swift-env.sh"

cd "$ROOT_DIR/apps/macos/Markdown"
swift test \
  --disable-sandbox \
  --cache-path "$MARKDOWN_SWIFT_CACHE_PATH" \
  --scratch-path "$MARKDOWN_SWIFT_SCRATCH_PATH" \
  --manifest-cache local
