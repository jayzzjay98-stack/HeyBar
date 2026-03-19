#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_BINARY="/Applications/HeyBar.app/Contents/MacOS/HeyBar"
OUTPUT_DIR="$ROOT_DIR/docs/release/screenshots"

mkdir -p "$OUTPUT_DIR"

if [[ ! -x "$APP_BINARY" ]]; then
  echo "Expected installed app binary at $APP_BINARY" >&2
  exit 1
fi

osascript -e 'try' -e 'tell application "HeyBar" to quit' -e 'end try' >/dev/null 2>&1 || true

HEYBAR_CAPTURE_SETTINGS=1 "$APP_BINARY" >/tmp/heybar-capture-settings.log 2>&1 &
sleep 2
SETTINGS_WINDOW_ID="$(swift "$ROOT_DIR/scripts/capture_window.swift" --owner "HeyBar")"
/usr/sbin/screencapture -x -l "$SETTINGS_WINDOW_ID" "$OUTPUT_DIR/settings-window.png"
osascript -e 'try' -e 'tell application "HeyBar" to quit' -e 'end try' >/dev/null 2>&1 || true

HEYBAR_CAPTURE_QUICK_CONTROLS=1 "$APP_BINARY" >/tmp/heybar-capture-panel.log 2>&1 &
sleep 2
PANEL_WINDOW_ID="$(swift "$ROOT_DIR/scripts/capture_window.swift" --owner "HeyBar")"
/usr/sbin/screencapture -x -l "$PANEL_WINDOW_ID" "$OUTPUT_DIR/quick-controls.png"
osascript -e 'try' -e 'tell application "HeyBar" to quit' -e 'end try' >/dev/null 2>&1 || true

echo "Saved screenshots to $OUTPUT_DIR"
