#!/bin/zsh
# Usage: ./scripts/release.sh <version>
# Example: ./scripts/release.sh 0.3.0
#
# This script:
#   1. Builds HeyBar.app with the new version
#   2. Zips it
#   3. Signs the zip with your EdDSA private key
#   4. Updates appcast.xml with the new release entry
#   5. Prints instructions for creating the GitHub Release
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <version>  (e.g. $0 0.3.0)"
  exit 1
fi

VERSION="$1"
BUILD="${2:-$(date +%Y%m%d)}"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_PATH="$DIST_DIR/HeyBar.app"
ZIP_PATH="$DIST_DIR/HeyBar-$VERSION.zip"

# ── Find sign_update tool ───────────────────────────────────────────────────
SPARKLE_XCFW=$(find "$ROOT_DIR/.build/artifacts" -name "Sparkle.xcframework" 2>/dev/null | head -1)
SIGN_UPDATE=$(find "$SPARKLE_XCFW" -name "sign_update" 2>/dev/null | head -1)

if [[ -z "$SIGN_UPDATE" ]]; then
  echo "sign_update not found. Downloading Sparkle tools..."
  SPARKLE_VERSION="2.6.4"
  TMPDIR_PATH=$(mktemp -d)
  curl -L "https://github.com/sparkle-project/Sparkle/releases/download/$SPARKLE_VERSION/Sparkle-$SPARKLE_VERSION.tar.xz" \
    -o "$TMPDIR_PATH/sparkle.tar.xz"
  tar -xf "$TMPDIR_PATH/sparkle.tar.xz" -C "$TMPDIR_PATH"
  SIGN_UPDATE=$(find "$TMPDIR_PATH" -name "sign_update" | head -1)
fi

if [[ -z "$SIGN_UPDATE" ]]; then
  echo "Error: Could not find sign_update binary." >&2
  exit 1
fi
chmod +x "$SIGN_UPDATE"

# ── Update version in Info.plist ────────────────────────────────────────────
echo "Setting version to $VERSION (build $BUILD)..."
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$ROOT_DIR/AppBundle/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD" "$ROOT_DIR/AppBundle/Info.plist"

# ── Build ────────────────────────────────────────────────────────────────────
echo "Building HeyBar $VERSION..."
zsh "$ROOT_DIR/scripts/install_app.sh"

# ── Zip ──────────────────────────────────────────────────────────────────────
echo "Creating zip archive..."
rm -f "$ZIP_PATH"
cd "$DIST_DIR"
zip -r --symlinks "HeyBar-$VERSION.zip" "HeyBar.app"
cd "$ROOT_DIR"

FILE_SIZE=$(stat -f%z "$ZIP_PATH")
DOWNLOAD_URL="https://github.com/jayzzjay98-stack/HeyBar/releases/download/v$VERSION/HeyBar-$VERSION.zip"

# ── Sign ─────────────────────────────────────────────────────────────────────
echo "Signing with EdDSA private key..."
SIGNATURE=$("$SIGN_UPDATE" "$ZIP_PATH" | grep "sparkle:edSignature" | sed 's/.*sparkle:edSignature="\([^"]*\)".*/\1/')

if [[ -z "$SIGNATURE" ]]; then
  SIGNATURE=$("$SIGN_UPDATE" "$ZIP_PATH")
fi

echo "Signature: $SIGNATURE"

# ── Update appcast.xml ───────────────────────────────────────────────────────
PUB_DATE=$(date -u "+%a, %d %b %Y %H:%M:%S +0000")

python3 - <<PYEOF
import xml.etree.ElementTree as ET

ET.register_namespace('sparkle', 'http://www.andymatuschak.org/xml-namespaces/sparkle')
ET.register_namespace('dc', 'http://purl.org/dc/elements/1.1/')

tree = ET.parse('appcast.xml')
root = tree.getroot()
channel = root.find('channel')

item = ET.SubElement(channel, 'item')
ET.SubElement(item, 'title').text = 'Version $VERSION'
ET.SubElement(item, '{http://www.andymatuschak.org/xml-namespaces/sparkle}releaseNotesLink').text = \
    'https://github.com/jayzzjay98-stack/HeyBar/releases/tag/v$VERSION'
ET.SubElement(item, 'pubDate').text = '$PUB_DATE'
ET.SubElement(item, '{http://www.andymatuschak.org/xml-namespaces/sparkle}minimumSystemVersion').text = '13.0'
enc = ET.SubElement(item, 'enclosure')
enc.set('url', '$DOWNLOAD_URL')
enc.set('{http://www.andymatuschak.org/xml-namespaces/sparkle}edSignature', '$SIGNATURE')
enc.set('length', '$FILE_SIZE')
enc.set('type', 'application/octet-stream')
enc.set('{http://www.andymatuschak.org/xml-namespaces/sparkle}version', '$BUILD')
enc.set('{http://www.andymatuschak.org/xml-namespaces/sparkle}shortVersionString', '$VERSION')

tree.write('appcast.xml', xml_declaration=True, encoding='utf-8')
print('appcast.xml updated.')
PYEOF

echo ""
echo "═══════════════════════════════════════════════════"
echo "  Release $VERSION ready!"
echo "═══════════════════════════════════════════════════"
echo ""
echo "Next steps:"
echo "  1. git add appcast.xml AppBundle/Info.plist"
echo "  2. git commit -m 'release: v$VERSION'"
echo "  3. git push"
echo "  4. Go to GitHub → Releases → Create new release"
echo "     Tag: v$VERSION"
echo "     Upload: dist/HeyBar-$VERSION.zip"
echo "  5. Done — existing users will see the update prompt automatically"
