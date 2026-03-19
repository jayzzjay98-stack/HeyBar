#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="HeyBar.app"
APP_BUNDLE_DIR="$ROOT_DIR/dist/$APP_NAME"
MACOS_DIR="$APP_BUNDLE_DIR/Contents/MacOS"
RESOURCES_DIR="$APP_BUNDLE_DIR/Contents/Resources"
INSTALL_TARGET="/Applications/$APP_NAME"
APP_BUNDLE_ID="com.gravity.heybar"

echo "Building release binary..."
CLANG_MODULE_CACHE_PATH=/tmp/codex-swift-cache swift build -c release --product "HeyBar"
BIN_DIR="$(CLANG_MODULE_CACHE_PATH=/tmp/codex-swift-cache swift build -c release --show-bin-path)"
APP_EXECUTABLE="$BIN_DIR/HeyBar"

echo "Assembling app bundle..."
rm -rf "$APP_BUNDLE_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp "$ROOT_DIR/AppBundle/Info.plist" "$APP_BUNDLE_DIR/Contents/Info.plist"
if [[ -f "$ROOT_DIR/AppBundle/PrivacyInfo.xcprivacy" ]]; then
  cp "$ROOT_DIR/AppBundle/PrivacyInfo.xcprivacy" "$RESOURCES_DIR/PrivacyInfo.xcprivacy"
fi
cp "$APP_EXECUTABLE" "$MACOS_DIR/HeyBar"
if [[ -f "$ROOT_DIR/AppBundle/AppIcon.icns" ]]; then
  cp "$ROOT_DIR/AppBundle/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi
chmod +x "$MACOS_DIR/HeyBar"

echo "Code signing app bundle..."
codesign --force --deep --sign - --identifier "$APP_BUNDLE_ID" "$APP_BUNDLE_DIR"

if [[ "${1:-}" == "--install" ]]; then
  echo "Installing to $INSTALL_TARGET..."
  rm -rf "$INSTALL_TARGET"
  cp -R "$APP_BUNDLE_DIR" "$INSTALL_TARGET"
  echo "Code signing installed app..."
  codesign --force --deep --sign - --identifier "$APP_BUNDLE_ID" "$INSTALL_TARGET"
  echo "Installed: $INSTALL_TARGET"
else
  echo "App bundle ready at: $APP_BUNDLE_DIR"
fi
