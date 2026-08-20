#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="${HOME}/Applications"
APP="${APP_DIR}/CursorUsageBar.app"
BIN_NAME="CursorUsageBar"

echo "Building ${BIN_NAME}…"
cd "$ROOT"
swift build -c release

BIN="${ROOT}/.build/release/${BIN_NAME}"
test -x "$BIN"

echo "Installing to ${APP}…"
mkdir -p "${APP}/Contents/MacOS" "${APP}/Contents/Resources"
cp "$BIN" "${APP}/Contents/MacOS/${BIN_NAME}"

cat > "${APP}/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>${BIN_NAME}</string>
  <key>CFBundleIdentifier</key>
  <string>local.cursorusagebar</string>
  <key>CFBundleName</key>
  <string>${BIN_NAME}</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

codesign --force --deep --sign - "$APP" >/dev/null 2>&1 || true

killall "$BIN_NAME" 2>/dev/null || true
open "$APP"

echo "Done. Look for \"C …%\" in the macOS menu bar."
echo "Optional: System Settings → General → Login Items → add CursorUsageBar."
