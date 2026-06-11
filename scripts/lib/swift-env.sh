#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

export HOME="$ROOT_DIR/.build/home"
export CLANG_MODULE_CACHE_PATH="$ROOT_DIR/.build/clang-module-cache"
export MARKDOWN_SWIFT_CACHE_PATH="$ROOT_DIR/.build/swiftpm-cache"
export MARKDOWN_SWIFT_SCRATCH_PATH="$ROOT_DIR/apps/macos/Markdown/.build"

mkdir -p "$HOME" "$CLANG_MODULE_CACHE_PATH" "$MARKDOWN_SWIFT_CACHE_PATH" "$MARKDOWN_SWIFT_SCRATCH_PATH"
