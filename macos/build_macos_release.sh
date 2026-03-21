#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/build/dist"
VERSION="$(sed -n 's/^version:[[:space:]]*//p' "$ROOT_DIR/pubspec.yaml" | head -n1)"
PRODUCTS_DIR="$ROOT_DIR/build/macos/Build/Products/Release"

if [[ -z "$VERSION" ]]; then
  echo "Unable to determine version from pubspec.yaml" >&2
  exit 1
fi

export FLUTTER_STORAGE_BASE_URL="${FLUTTER_STORAGE_BASE_URL:-https://storage.flutter-io.cn}"
export PUB_HOSTED_URL="${PUB_HOSTED_URL:-https://pub.flutter-io.cn}"

if [[ "${SKIP_FLUTTER_BUILD:-0}" != "1" ]]; then
  flutter build macos --target lib/main.dart --release
fi

APP_PATH="$(find "$PRODUCTS_DIR" -maxdepth 1 -type d -name '*.app' | head -n1)"
if [[ -z "$APP_PATH" ]]; then
  echo "Unable to locate built macOS .app under $PRODUCTS_DIR" >&2
  exit 1
fi

mkdir -p "$DIST_DIR"
ZIP_PATH="$DIST_DIR/vertree-macos-$VERSION.zip"
DMG_PATH="$DIST_DIR/vertree-macos-$VERSION.dmg"
DMG_STAGE_DIR="$DIST_DIR/dmg-stage"

rm -f "$ZIP_PATH" "$DMG_PATH"
rm -rf "$DMG_STAGE_DIR"
mkdir -p "$DMG_STAGE_DIR"

cp -R "$APP_PATH" "$DMG_STAGE_DIR/"
ln -s /Applications "$DMG_STAGE_DIR/Applications"

ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"
hdiutil create \
  -volname "Vertree" \
  -srcfolder "$DMG_STAGE_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

rm -rf "$DMG_STAGE_DIR"

echo "macOS zip created: $ZIP_PATH"
echo "macOS dmg created: $DMG_PATH"
