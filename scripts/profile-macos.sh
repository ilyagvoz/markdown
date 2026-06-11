#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_PATH="$ROOT_DIR/artifacts/Markdown.app"
OPEN_PATH="${1:-$ROOT_DIR/spikes/spike1-rendering-engine/fixtures}"
SAMPLES="${SAMPLES:-12}"
INTERVAL_SECONDS="${INTERVAL_SECONDS:-1}"
export CONFIGURATION="${CONFIGURATION:-release}"

"$ROOT_DIR/scripts/build-macos-app.sh" >/dev/null

osascript -e 'tell application "Markdown" to quit' >/dev/null 2>&1 || true
open -n "$APP_PATH" --args --open "$OPEN_PATH"
sleep 2

PID="$(pgrep -n -x Markdown)"
echo "Profiling Markdown pid=$PID path=$OPEN_PATH samples=$SAMPLES interval=${INTERVAL_SECONDS}s"
echo "sample,cpu_percent,rss_mb,vsz_mb"

for sample in $(seq 1 "$SAMPLES"); do
  line="$(ps -p "$PID" -o %cpu=,rss=,vsz=)"
  cpu="$(awk '{print $1}' <<<"$line")"
  rss_kb="$(awk '{print $2}' <<<"$line")"
  vsz_kb="$(awk '{print $3}' <<<"$line")"
  rss_mb="$(awk "BEGIN { printf \"%.1f\", $rss_kb / 1024 }")"
  vsz_mb="$(awk "BEGIN { printf \"%.1f\", $vsz_kb / 1024 }")"
  echo "$sample,$cpu,$rss_mb,$vsz_mb"
  sleep "$INTERVAL_SECONDS"
done

osascript -e 'tell application "Markdown" to quit' >/dev/null 2>&1 || true
