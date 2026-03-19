#!/bin/zsh
set -euo pipefail

APP_PATH="/Applications/HeyBar.app"

if [[ ! -d "$APP_PATH" ]]; then
  echo "HeyBar.app is not installed in /Applications."
  exit 1
fi

echo "Launching $APP_PATH..."
open -a "$APP_PATH"
sleep 2

echo "Checking whether HeyBar reports as running..."
RUNNING=$(osascript -e 'application "HeyBar" is running')
echo "Running: $RUNNING"

if [[ "$RUNNING" != "true" ]]; then
  echo "HeyBar did not report as running."
  exit 1
fi

echo "Quitting HeyBar..."
osascript -e 'tell application "HeyBar" to quit'
sleep 1

echo "Smoke check passed."
