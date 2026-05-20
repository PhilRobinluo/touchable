#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="TouchAble"
BUNDLE_ID="com.philrobin.TouchAble"
MIN_SYSTEM_VERSION="14.0"
SIGN_IDENTITY="${TOUCHABLE_CODESIGN_IDENTITY:-TouchAble Local Dev}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
INSTALLED_APP_BUNDLE="${TOUCHABLE_INSTALLED_APP_BUNDLE:-$HOME/Applications/$APP_NAME.app}"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"

cd "$ROOT_DIR"

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

swift build
BUILD_BINARY="$(swift build --show-bin-path)/$APP_NAME"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"

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
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
  <key>NSAppleEventsUsageDescription</key>
  <string>TouchAble uses macOS accessibility APIs only to detect the type of UI element under the pointer.</string>
  <key>NSAccessibilityUsageDescription</key>
  <string>TouchAble uses accessibility only to detect whether the pointer is over a button, link, text, input field, or similar UI role.</string>
  <key>NSInputMonitoringUsageDescription</key>
  <string>TouchAble uses input monitoring only to detect mouse clicks, drags, and scrolls for haptic feedback.</string>
  <key>NSHumanReadableCopyright</key>
  <string>Local internal build</string>
</dict>
</plist>
PLIST

if /usr/bin/codesign --force --sign "$SIGN_IDENTITY" --identifier "$BUNDLE_ID" "$APP_BUNDLE" >/dev/null 2>&1; then
  echo "Signed with identity: $SIGN_IDENTITY"
else
  echo "warning: signing identity '$SIGN_IDENTITY' is not available; falling back to ad-hoc signing" >&2
  echo "warning: run ./script/setup_local_signing.sh to improve Accessibility/Input Monitoring permission stability" >&2
  /usr/bin/codesign --force --sign - --identifier "$BUNDLE_ID" "$APP_BUNDLE" >/dev/null
fi

mkdir -p "$(dirname "$INSTALLED_APP_BUNDLE")"
rm -rf "$INSTALLED_APP_BUNDLE"
/usr/bin/ditto "$APP_BUNDLE" "$INSTALLED_APP_BUNDLE"
echo "Installed local app: $INSTALLED_APP_BUNDLE"

open_app() {
  /usr/bin/open -n "$INSTALLED_APP_BUNDLE"
}

open_debug_app() {
  /usr/bin/open -n "$INSTALLED_APP_BUNDLE" --args --open-debug
}

open_permission_setup() {
  /usr/bin/open -R "$INSTALLED_APP_BUNDLE"
  /usr/bin/open "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent"
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --debug-ui|debug-ui)
    open_debug_app
    ;;
  --permissions|permissions|--privacy-setup|privacy-setup)
    open_permission_setup
    ;;
  --verify|verify)
    open_app
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--debug-ui|--permissions|--verify]" >&2
    exit 2
    ;;
esac
