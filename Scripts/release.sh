#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
PROJECT="MacAutoBackground.xcodeproj"
SCHEME="MacAutoBackground"
DERIVED="$ROOT_DIR/build/Derived"
if [[ "${1:-}" != "" ]]; then
  VERSION="$1"
else
  VERSION="$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Release -showBuildSettings 2>/dev/null | sed -n 's/^ *MARKETING_VERSION = //p' | tail -n 1)"
  if [[ -z "$VERSION" ]]; then
    VERSION="1.0.0"
  fi
fi
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Release -derivedDataPath "$DERIVED" -quiet build
APP_PATH="$DERIVED/Build/Products/Release/MacAutoBackground.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "App not found at $APP_PATH"
  exit 1
fi
DIST_DIR="$ROOT_DIR/dist"
mkdir -p "$DIST_DIR"
ZIP_PATH="$DIST_DIR/MacAutoBackground_v${VERSION}.zip"
DMG_PATH="$DIST_DIR/MacAutoBackground_v${VERSION}.dmg"
rm -f "$ZIP_PATH" "$DMG_PATH"
cd "$(dirname "$APP_PATH")"
zip -yr "$ZIP_PATH" "MacAutoBackground.app"
hdiutil create -volname "MacAutoBackground v${VERSION}" -srcfolder "MacAutoBackground.app" -ov -format UDZO "$DMG_PATH"
echo "$ZIP_PATH"
echo "$DMG_PATH"
