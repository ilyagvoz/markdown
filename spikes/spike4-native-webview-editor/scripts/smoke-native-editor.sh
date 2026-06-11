#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

swift test --package-path "$ROOT"
swift build --package-path "$ROOT"

"$ROOT/.build/debug/NativeWebViewEditorSpike" --smoke &
pid=$!

for _ in {1..20}; do
  if ! kill -0 "$pid" 2>/dev/null; then
    wait "$pid"
    exit $?
  fi
  sleep 1
done

kill "$pid" 2>/dev/null || true
wait "$pid" 2>/dev/null || true
echo "SMOKE_FAIL native WebView editor did not terminate within timeout" >&2
exit 1
