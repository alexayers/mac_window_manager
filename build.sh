#!/usr/bin/env bash
# Build the Sizer executable and assemble a signed .app bundle that can hold
# Accessibility permission. Ad-hoc signing is sufficient for local use.
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="Sizer"
BUNDLE_ID="com.diskrot.Sizer"
CONFIG="release"

echo "==> swift build ($CONFIG)"
swift build -c "$CONFIG"

BIN_DIR="$(swift build -c "$CONFIG" --show-bin-path)"
BIN_PATH="$BIN_DIR/$APP_NAME"
APP_DIR="$APP_NAME.app"

echo "==> Assembling $APP_DIR"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"
cp "$BIN_PATH" "$APP_DIR/Contents/MacOS/$APP_NAME"
cp Info.plist "$APP_DIR/Contents/Info.plist"

# Prefer a stable local identity ("Sizer Dev") so the Accessibility grant
# survives rebuilds. Fall back to ad-hoc if the cert isn't installed (in which
# case the grant breaks on each rebuild — see setup-signing.sh).
SIGN_IDENTITY="Sizer Dev"
if codesign --force --deep --sign "$SIGN_IDENTITY" --identifier "$BUNDLE_ID" "$APP_DIR" 2>/dev/null; then
  echo "==> Signed with '$SIGN_IDENTITY' (stable identity)"
else
  echo "==> '$SIGN_IDENTITY' unavailable; ad-hoc signing (grant won't persist across rebuilds)"
  codesign --force --deep --sign - --identifier "$BUNDLE_ID" "$APP_DIR"
fi

echo "==> Done: $(pwd)/$APP_DIR"
echo
echo "Run with:  open ./$APP_DIR"
echo "First launch: grant Accessibility in System Settings > Privacy & Security > Accessibility."
