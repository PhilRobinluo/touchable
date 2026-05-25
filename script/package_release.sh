#!/usr/bin/env bash
set -euo pipefail

APP_NAME="TouchAble"
BUNDLE_ID="com.philrobin.TouchAble"
MIN_SYSTEM_VERSION="14.0"
SIGN_IDENTITY="${TOUCHABLE_CODESIGN_IDENTITY:-TouchAble Local Dev}"
VERSION="${1:-$(date +%Y.%m.%d)}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
RELEASE_DIR="$DIST_DIR/release"
APP_BUNDLE="$RELEASE_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
APP_ICON="$ROOT_DIR/Resources/AppIcon.icns"
ZIP_PATH="$RELEASE_DIR/$APP_NAME-$VERSION-macos.zip"

cd "$ROOT_DIR"

swift build -c release
BUILD_BINARY="$(swift build -c release --show-bin-path)/$APP_NAME"

rm -rf "$RELEASE_DIR"
mkdir -p "$APP_MACOS"
mkdir -p "$APP_RESOURCES"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"

if [[ -f "$APP_ICON" ]]; then
  cp "$APP_ICON" "$APP_RESOURCES/AppIcon.icns"
fi

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundleDisplayName</key>
  <string>$APP_NAME</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$VERSION</string>
  <key>CFBundleVersion</key>
  <string>$VERSION</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
  <key>NSAppleEventsUsageDescription</key>
  <string>TouchAble posts configured keyboard shortcuts for explicit gesture mappings.</string>
  <key>NSAccessibilityUsageDescription</key>
  <string>TouchAble uses accessibility only to detect whether the pointer is over a button, link, text, input field, or similar UI role.</string>
  <key>NSInputMonitoringUsageDescription</key>
  <string>TouchAble uses input monitoring only to detect mouse clicks, drags, and scrolls for haptic feedback and gesture mappings.</string>
  <key>NSHumanReadableCopyright</key>
  <string>MIT License</string>
</dict>
</plist>
PLIST

if /usr/bin/codesign --force --sign "$SIGN_IDENTITY" --identifier "$BUNDLE_ID" "$APP_BUNDLE" >/dev/null 2>&1; then
  echo "Signed with identity: $SIGN_IDENTITY"
else
  echo "warning: signing identity '$SIGN_IDENTITY' is not available; falling back to ad-hoc signing" >&2
  /usr/bin/codesign --force --sign - --identifier "$BUNDLE_ID" "$APP_BUNDLE" >/dev/null
fi

/usr/bin/codesign --verify --deep --strict "$APP_BUNDLE"
rm -f "$ZIP_PATH"
(cd "$RELEASE_DIR" && COPYFILE_DISABLE=1 /usr/bin/zip -qry -X "$ZIP_PATH" "$APP_NAME.app")
COPYFILE_DISABLE=1 /usr/bin/ditto -x -k "$ZIP_PATH" "$RELEASE_DIR/verify-unzip"
test -x "$RELEASE_DIR/verify-unzip/$APP_NAME.app/Contents/MacOS/$APP_NAME"
rm -rf "$RELEASE_DIR/verify-unzip"

echo "Created package: $ZIP_PATH"
echo "Package size: $(/usr/bin/du -h "$ZIP_PATH" | awk '{print $1}')"
echo "SHA256: $(/usr/bin/shasum -a 256 "$ZIP_PATH" | awk '{print $1}')"
