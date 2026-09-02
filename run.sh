#!/usr/bin/env bash
# Build, sign, and launch the app.
set -euo pipefail
cd "$(dirname "$0")"

./build.sh

# Relaunch cleanly so a rebuild picks up the new binary. Matched by exact name
# "Sizer" (distinct from Apple's system "WindowManager" daemon).
pkill -x Sizer 2>/dev/null || true
open "./Sizer.app"
echo "==> Launched Sizer.app (look for the icon in the menu bar)."
